local uci = require('simple-uci').cursor()

local site = require 'gluon.site'
local util = require 'gluon.util'
local vpn_core = require 'gluon.mesh-vpn'

local M = {}

function M.public_key()
        return util.trim(util.exec('/usr/bin/wg show wg_mesh_vpn public-key'))
end

function M.enable(val)
        uci:set('gluon', 'mesh_vpn', 'enabled', val)
        uci:save('gluon')
end

function M.active()
        return site.mesh_vpn.wireguard() ~= nil
end

function M.set_limit(ingress_limit, egress_limit)
        uci:delete('simple-tc', 'mesh_vpn')
        if ingress_limit ~= nil and egress_limit ~= nil then
                uci:section('simple-tc', 'interface', 'mesh_vpn', {
                        ifname = vpn_core.get_interface(),
                        enabled = true,
                        limit_egress = egress_limit,
                        limit_ingress = ingress_limit,
                })
        end

        uci:save('simple-tc')
end

function M.mtu()
	return site.mesh_vpn.wireguard.mtu()
end

return M
