#!/usr/bin/lua

local uci = require("simple-uci").cursor()
local hash = require 'hash'
local util = require 'gluon.util'

local RT_PROTO = '23'

function log(msg)
	util.log("checkuplink: " .. msg)
end

function wg_pubkey()
	local privkey = uci:get("wireguard", "mesh_vpn", "privatekey")
	return io.popen("echo " .. privkey .. " | wg pubkey"):read("*l")
end

function interface_linklocal()
	local md5 = hash.md5(wg_pubkey() .. "\n")
	return "fe80::" .. md5:sub(1, 2) .. ":" .. md5:sub(3, 4) .. "ff:fe" .. md5:sub(5, 6) .. ":" .. md5:sub(7, 10)
end

function reconnect_wireguard(has_ipv6_gateway)
	log("reconnecting...")
	local ntp_server = uci:get("wireguard", "mesh_vpn", "ntp")
	os.execute("gluon-wan /usr/sbin/ntpd -n -N -S /usr/sbin/ntpd-hotplug -p " .. ntp_server .. " -q")

	math.randomseed(os.time())

	local peers = {}
	uci:foreach("wireguard", "peer", function(peer)
		if peer.enabled ~= "1" then
			return
		end
		table.insert(peers, peer)
	end)

	local peer = peers[math.random(#peers)]
	local endpoint_name, endpoint_port = peer.endpoint:match("(.*):([0-9]+)$")

	log("connecting to " .. endpoint_name)
	if not has_ipv6_gateway then
	    local nslookup = io.popen("gluon-wan nslookup " .. endpoint_name)
	    for line in nslookup:lines() do
	        local addr = nil
	        addr = line:match("Address%s+%d+:%s+(%d+%.%d+%.%d+%.%d+)$")
	        if addr ~= nil then
	            endpoint_name = addr
	            break
	        end
	    end
	end

	os.execute("ip link delete dev wg")

	os.execute("ip link add dev wg type wireguard")
	os.execute("wg set wg fwmark 1")
	local private_key = uci:get("wireguard", "mesh_vpn", "privatekey")
	local wg_set = io.popen("wg set wg private-key /proc/self/fd/0", "w")
	wg_set:write(private_key .. "\n")
	wg_set:close()
	os.execute("ip link set up dev wg")
	os.execute("ip address add " .. interface_linklocal() .. "/64 dev wg")

	os.execute("gluon-wan wg set wg peer " .. peer.publickey .. " persistent-keepalive 25 allowed-ips ::/0 endpoint " .. endpoint_name .. ":" .. endpoint_port)
end

function stop_gateway()
	os.execute("sysctl net.ipv6.conf.br-client.forwarding=0")
end

function start_gateway(prefix)
	os.execute("sysctl net.ipv6.conf.br-client.forwarding=1")
end

function refresh_ips(current_peer_addr)
	local prefix = io.popen("nc " .. current_peer_addr .. "%wg 9999"):read("*l")
	if prefix == nil then
		log('failed to retrieve prefix')
		stop_gateway()
		return
	end
	prefix = prefix:match("^(%x+:[%x:]+/%d+)$")
	log("prefix: " .. prefix)
	
	local stored_prefix_fd = io.open("/tmp/vpn-prefix", "r")
	if stored_prefix_fd ~= nil then
		local stored_prefix = stored_prefix_fd:read("*l")
		stored_prefix_fd:close()
		log("stored prefix: " .. stored_prefix)
		if stored_prefix == prefix then
			return
		end
		log("new prefix")
		stop_gateway()
	end
	stored_prefix_fd = io.open("/tmp/vpn-prefix", "w")
	stored_prefix_fd:write(prefix .. "\n")
	stored_prefix_fd:close()
	start_gateway(prefix)
end

if uci:get("wireguard", "mesh_vpn", "privatekey") == nil then
	local privkey = io.popen("wg genkey"):read("*l")
	uci:set("wireguard", "mesh_vpn", "privatekey", privkey)
	uci:save("wireguard")
	uci:commit("wireguard")
end

if not uci:get_bool("wireguard", "mesh_vpn", "enabled") then
	os.exit(0)
end

log('checking mesh-vpn connection')
local wg_show = io.popen("wg show wg dump")
local current_peer_addr = nil
if wg_show:read("*l") ~= nil then
	local peer = wg_show:read("*l")
	if peer ~= nil then
		uci:foreach("wireguard", "peer", function(config_peer)
			if string.sub(peer,1,string.len(config_peer.publickey)) == config_peer.publickey then
				current_peer_addr = config_peer.link_address
			end
		end)
	end
end
wg_show:close()

if current_peer_addr then
	if os.execute("ping -c 1 -w 5 " .. current_peer_addr .. "%wg > /dev/null") == 0 then
		log("connection check ok")
		refresh_ips(current_peer_addr)
		os.exit(0)
	else
		log("ping of wireguard tunnel peer address " .. current_peer_addr .. " unsuccessful")
	end
else
	log("cannot determine wireguard tunnel peer address")
end

local has_ipv6_gateway = false
local ip_route = io.popen("ip -6 route show table 1")
for line in ip_route:lines() do
	if line:sub(1, 11) == "default via" then
		has_ipv6_gateway = true
		break
	end
end
ip_route:close()

local has_ipv4_gateway = false
ip_route = io.popen("ip route show")
for line in ip_route:lines() do
	if line:sub(1, 11) == "default via" then
		has_ipv4_gateway = true
		break
	end
end
ip_route:close()

if not has_ipv6_gateway and not has_ipv4_gateway then
	log('no default route found. exiting...')
	os.exit(0)
end

reconnect_wireguard(has_ipv6_gateway)
refresh_ips(current_peer_addr)
