return function(form, uci)
	local site = require 'gluon.site_config'

	local location = uci:get_first("gluon-node-info", "location")

	local function show_altitude()
		if ((site.config_mode or {}).geo_location_map or {}).show_altitude ~= false then
			return true
		end

		return uci:get_bool("gluon-node-info", location, "altitude")
	end

	local function show_map()
		if ((site.config_mode or {}).geo_location_map or {}).show_map ~= false then
			return true
		end

		return false
	end

	local text = translate(
		'If you want the location of your node to ' ..
		'be displayed on the map, you can enter its coordinates here.' ..
		'If your PC is connected to the internet you can also click on the map displayed below.'
	)
	if show_altitude() then
		text = text .. ' ' .. translate("gluon-config-mode:altitude-help")
	end

	if show_map() then
		text = text .. [[
			<div id="locationPickerMap" style="width:100%; height:300px; display: none;"></div>
			<script src="http://firmware.freifunk-myk.de/.static/ol/OpenLayers.js"></script>
			<script src="<%=media%>/osm.js"></script>
			<script>body.addEventListener("load", showMap, false);</script>
		]]
	end

	local s = form:section(Section, nil, text)

	local o

	local share_location = s:option(Flag, "location", translate("Show node on the map"))
	share_location.default = uci:get_bool("gluon-node-info", location, "share_location")
	function share_location:write(data)
		uci:set("gluon-node-info", location, "share_location", data)
	end

	o = s:option(Value, "latitude", translate("Latitude"), translatef("e.g. %s", "50.364931"))
	o.default = uci:get("gluon-node-info", location, "latitude")
	o:depends(share_location, true)
	o.datatype = "float"
	function o:write(data)
		uci:set("gluon-node-info", location, "latitude", data)
	end

	o = s:option(Value, "longitude", translate("Longitude"), translatef("e.g. %s", "7.606417"))
	o.default = uci:get("gluon-node-info", location, "longitude")
	o:depends(share_location, true)
	o.datatype = "float"
	function o:write(data)
		uci:set("gluon-node-info", location, "longitude", data)
	end

	if show_altitude() then
		o = s:option(Value, "altitude", translate("gluon-config-mode:altitude-label"), translatef("e.g. %s", "11.51"))
		o.default = uci:get("gluon-node-info", location, "altitude")
		o:depends(share_location, true)
		o.datatype = "float"
		o.optional = true
		function o:write(data)
			if data then
				uci:set("gluon-node-info", location, "altitude", data)
			else
				uci:delete("gluon-node-info", location, "altitude")
			end
		end
	end

	return {'gluon-node-info'}
end
