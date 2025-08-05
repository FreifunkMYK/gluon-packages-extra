#!/usr/bin/lua

local uci = require("simple-uci").cursor()
local hash = require 'hash'
local util = require 'gluon.util'

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

if uci:get("wireguard", "mesh_vpn", "privatekey") == nil then
	local privkey = io.popen("wg genkey"):read("*l")
	uci:set("wireguard", "mesh_vpn", "privatekey", privkey)
	uci:save("wireguard")
end

if not uci:get_bool("gluon", "mesh_vpn", "enabled") then
	os.exit(0)
end

local disable_vpn = io.open("/tmp/disable_vpn", "r")
if disable_vpn ~= nil then
	local disable_end_time = disable_vpn:read("*all")
	io.close(disable_vpn)
	local now = os.time()
	if now > disable_end_time then
		os.remove("/tmp/disable_vpn")
	else
		os.exit(0)
	end
end

log('checking mesh-vpn connection')
local wg_show = io.popen("wg show wg dump")
local current_peer_addr = nil
if wg_show:read("*l") ~= nil then
	local peer = wg_show:read("*l")
	if peer ~= nil then
		current_peer_addr = peer:match("fe80::[^/]*")
	end
end
wg_show:close()

if current_peer_addr then
	local f = io.open("/tmp/wg_endpoint_fallback", "r")
	local fallback = nil
	if f ~= nil then
		fallback = f:read("*all")
		f:close()
		os.remove("/tmp/wg_endpoint_fallback")
	end
	if os.execute("ping -c 1 -w 5 " .. current_peer_addr .. "%wg > /dev/null") == 0 then
		local gwmac = ""
		local batctl_gwl = io.popen("batctl gwl")
		for line in batctl_gwl:lines() do
			if line:sub(1, 1) == "*" then
				gwmac = line:sub(3, 19)
				break
			end
		end
		if os.execute("batctl ping -c 5 " .. gwmac .. " &> /dev/null") == 0 then
			log("connection check ok")
			os.exit(0)
		else
			log("batctl ping to gw mac " .. gwmac .. " unsuccessful")
		end
	else
		log("ping of wireguard tunnel peer address " .. current_peer_addr .. " unsuccessful")
	end

	if fallback ~= nil then
		log("trying ipv4 instead")
		os.execute("gluon-wan wg set wg peer " .. fallback)
		os.exit(0)
	end
else
	log("cannot determine wireguard tunnel peer address")
end

log("reconnecting...")
local ntp_server = uci:get("wireguard", "mesh_vpn", "ntp")
os.execute("gluon-wan /usr/sbin/ntpd -n -N -S /usr/sbin/ntpd-hotplug -p " .. ntp_server .. " -q")

math.randomseed(os.time())


local has_ipv6_gateway = false
local ip_route = io.popen("ip -6 route show table 1")
for line in ip_route:lines() do
	if line:sub(1, 11) == "default via" then
		has_ipv6_gateway = true
		break
	end
end
ip_route:close()


local peers = {}
uci:foreach("wireguard", "peer", function(peer)
	if peer.enabled ~= "1" then
		return
	end
	table.insert(peers, peer)
end)

local peer = nil
local endpoint_name = nil
local endpoint_ip = nil
local endpoint_port = nil

while peer == nil and #peers > 0 do
	local peer_pos = math.random(#peers)
	peer = peers[peer_pos]
	table.remove(peers, peer_pos)
	endpoint_name, endpoint_port = peer.endpoint:match("(.*):([0-9]+)$")

	log("resolving " .. endpoint_name .. "...")
	local nslookup = io.popen("gluon-wan nslookup " .. endpoint_name)
	local addr6 = nil
	local addr4 = nil
	for line in nslookup:lines() do
		if addr4 == nil then
			addr4 = line:match("Address:%s+(%d+%.%d+%.%d+%.%d+)$")
		end
		if addr6 == nil then
			addr6 = line:match("Address:%s+(%x+[:%x]+)$")
		end
	end
	if has_ipv6_gateway and addr6 ~= nil then
		endpoint_ip = "[" .. addr6 .. "]"
		local f = io.open("/tmp/wg_endpoint_fallback", "w")
		f:write(peer.publickey .. " endpoint " .. addr4 .. ":" .. endpoint_port)
		f:close()
		break
	end
	if addr4 ~= nil then
		endpoint_ip = addr4
		break
	end

	if endpoint_ip == nil then
		log("resolving " .. endpoint_name .. " failed")
		peer = nil
	end
end

if peer == nil then
	log("unable to resolve any peer")
	os.exit(0)
end

log("connecting to " .. endpoint_name .. "(" .. endpoint_ip .. ")")

os.execute("ip link set nomaster dev mesh-vpn")
os.execute("ip link delete dev mesh-vpn")
os.execute("ip link delete dev wg")

os.execute("ip link add dev wg type wireguard")
os.execute("wg set wg fwmark 1")
local private_key = uci:get("wireguard", "mesh_vpn", "privatekey")
local wg_set = io.popen("wg set wg private-key /proc/self/fd/0", "w")
wg_set:write(private_key .. "\n")
wg_set:close()
os.execute("ip link set up dev wg")
os.execute("ip address add " .. interface_linklocal() .. "/64 dev wg")

os.execute("gluon-wan wg set wg peer " .. peer.publickey .. " persistent-keepalive 25 allowed-ips " .. peer.link_address .. "/128 endpoint " .. endpoint_ip .. ":" .. endpoint_port)
os.execute("ip6tables -I INPUT 1 -i wg -m udp -p udp --dport 8472 -j ACCEPT")

local vxlan_id = tonumber(util.domain_seed_bytes("gluon-mesh-vpn-vxlan", 3), 16)
os.execute("ip link add mesh-vpn type vxlan id " .. vxlan_id .. " local " .. interface_linklocal() .. " remote " .. peer.link_address .. " dstport 8472 dev wg")
os.execute("ip link set up dev mesh-vpn")
