#!/usr/bin/lua

local uci = require("simple-uci").cursor()
local hash = require 'hash'
local util = require 'gluon.util'
local site = require 'gluon.site'

local RT_PROTO = '23'

function log(msg)
	util.log("checkuplink: " .. msg)
end

function sleep(n)
  os.execute("sleep " .. tonumber(n))
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
	log('stopping gateway')
	stored_prefix_fd = io.open("/tmp/vpn-prefix", "w")
	stored_prefix_fd:close()
	os.execute("sysctl net.ipv6.conf.br-client.forwarding=0")
	os.execute("rmmod jool_siit")
	os.execute("/etc/init.d/gluon-ebtables restart")

	uci:set('dhcp', 'local_client', 'ignore', '1')
	uci:set('network', 'client', 'proto', 'dhcp')
	uci:delete('network', 'client', 'ipaddr')
	uci:delete('network', 'client', 'ip6addr')
	uci:set('network', 'client6', 'proto', 'dhcpv6')
	uci:set('network', 'gluon_bat0', 'gw_mode', 'client')

	uci:commit('dhcp')
	uci:commit('network')

	os.execute("ebtables-tiny -F RADV_FILTER")
	os.execute("/etc/init.d/gluon-radv-filterd start")
	os.execute("/etc/init.d/ffmyk-radvd stop")
	os.execute("/etc/init.d/network reload")

end

function start_gateway(prefix)
	local slash_pos = prefix:find("/")
	local prefix_net = prefix:sub(0,slash_pos-1)
	log('starting gateway')
	os.execute("sysctl net.ipv6.conf.br-client.forwarding=1")
	os.execute("ebtables-tiny -D INPUT -p IPv6 -i bat0 --ip6-proto ipv6-icmp --ip6-icmp-type router-solicitation -j DROP")
	os.execute("ebtables-tiny -D OUTPUT -p IPv6 -o bat0 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j DROP")
	os.execute("ebtables-tiny -I FORWARD 1 -i br-client --logical-in br-client -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT")

	os.execute("ip -6 route replace default dev wg proto " .. RT_PROTO)

	uci:set('dhcp', 'local_client', 'interface', 'client')
	uci:set('dhcp', 'local_client', 'ignore', '0')
	uci:set('dhcp', 'local_client', 'leasetime', '5m')
	uci:set('dhcp', 'local_client', 'start', '2')
	uci:set('dhcp', 'local_client', 'limit', '65532')
	uci:set('dhcp', 'local_client', 'force', '1')

	uci:set('network', 'local_node', 'ipaddr', site.next_node.ip4() .. '/32')
	uci:set('network', 'client', 'proto', 'static')
	uci:set('network', 'client', 'ipaddr', '10.222.0.1/16')
	uci:set('network', 'client', 'ip6addr', prefix_net .. "1/64")
	uci:set('network', 'client6', 'proto', 'static')
	uci:set('network', 'gluon_bat0', 'gw_mode', 'server')

	uci:commit('dhcp')
	uci:commit('network')

	os.execute("/etc/init.d/gluon-radv-filterd stop")

	os.execute("/etc/init.d/network reload")

	local radvd_arguments_fd = io.open("/tmp/ffmyk_radvd_arguments", "w")
	radvd_arguments_fd:write("-i br-client ")
	radvd_arguments_fd:write("-p " .. prefix .. " ")
	radvd_arguments_fd:write("--default-lifetime 900 ")
	radvd_arguments_fd:write("--rdnss " .. site.next_node.ip6())
	radvd_arguments_fd:close()

	sleep(2)

	os.execute("ebtables-tiny -F RADV_FILTER")
	os.execute("/etc/init.d/ffmyk-radvd start")
	os.execute("/etc/init.d/dnsmasq restart")

	os.execute("insmod jool_siit")
	os.execute("jool_siit -6 64:ff9b::/96")
	os.execute("jool_siit -e -a 10.222.0.0/16 " .. prefix_net .. "/112")
end

function refresh_ips(current_peer_addr)
	log('refreshing ipv6 prefix...')
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

function get_current_peer_addr()
	local current_peer_addr = nil
	local wg_show = io.popen("wg show wg dump")
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
	return current_peer_addr
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
local current_peer_addr = get_current_peer_addr()

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
	os.execute("ip link delete dev wg")
	os.exit(0)
end

reconnect_wireguard(has_ipv6_gateway)
local current_peer_addr = get_current_peer_addr()
os.execute("ping -c 1 -w 10 " .. current_peer_addr .. "%wg > /dev/null")
refresh_ips(current_peer_addr)
