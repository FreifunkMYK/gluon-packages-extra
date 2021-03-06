local uci = require("simple-uci").cursor()

local site = require 'gluon.site'
local sysconfig = require 'gluon.sysconfig'
local util = require "gluon.util"

local pretty_hostname = require 'pretty_hostname'

local meshvpn_enabled = uci:get_bool("fastd", "mesh_vpn", "enabled")

local hostname = pretty_hostname.get(uci)
local contact = uci:get_first("gluon-node-info", "owner", "contact")

local pubkey
local msg

local function get_prefix()
        return site.config_mode.qrcode.url_prefix(false)
end

local function get_suffix()
        return site.config_mode.qrcode.url_suffix('')
end

local function is_active()
        return site.config_mode.qrcode.show_qrcode(false)
end

local function toUnicode(a)
        a1,a2,a3,a4 = a:byte(1, -1)
        ans = string.format ("%%%02X", a1)
        n = a2
        if (n) then
                ans = ans .. string.format ("%%%02X", n)
        end
        n = a3
        if (n) then
                ans = ans .. string.format ("%%%02X", n)
        end
        n = a4
        if (n) then
                ans = ans .. string.format ("%%%02X", n)
        end
        return ans
end

local function urlencode(str)
        if (str) then
                str = string.gsub (str, "\n", "\r\n")
                str = string.gsub (str, "([^%w ])", toUnicode)
                str = string.gsub (str, " ", "+")
        end
        return str
end

local prefix = get_prefix()

if (meshvpn_enabled and is_active and prefix ~= false) then

        pubkey = util.trim(util.exec("/etc/init.d/fastd show_key mesh_vpn"))
        msg = [[
        <script src="/static/gluon-web-qrcode.js"></script>
        <script>/* <![CDATA[ */
                function chkQr() {
                        if(document.getElementById("qrdiv")) {
                                var qr = qrcode(0,'L');
                                qr.addData("]] .. prefix .. "mac=" .. urlencode(sysconfig.primary_mac) .. "&key=" .. urlencode(pubkey) .. "&host=" .. urlencode(hostname) .. "&contact="
	if(contact) then
		msg = msg .. urlencode(contact);
	end
	msg = msg .. [[");
                                qr.make();
                                document.getElementById("qrdiv").innerHTML = qr.createImgTag();
                        }
                }
        ]] .. "/* ]]>" .. [[ */</script>
        <script>document.addEventListener("DOMContentLoaded", chkQr, false);</script>
        <br/><div id="qrdiv"></div>
        ]];
end

if not msg then return end

renderer.render_string(msg)
