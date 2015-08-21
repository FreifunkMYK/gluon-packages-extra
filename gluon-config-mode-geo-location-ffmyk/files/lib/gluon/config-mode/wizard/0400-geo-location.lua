local cbi = require "luci.cbi"
local uci = luci.model.uci.cursor()

local M = {}

function M.section(form)
  local s = form:section(cbi.SimpleSection, nil,
    [[Um deinen Knoten auf der Karte anzeigen zu können, benötigen
    wir seine Koordinaten. Hier hast du die Möglichkeit, diese zu
    hinterlegen.
    
    <!-- Beware: Ugly hacks ahead -->
    <div id="locationPickerMap" style="width:100%; height:300px; display: none;"></div>


    <script type="text/javascript">
        /*  Center coordinated if node has no position - adjust to your city */
        var latitude = 50.356667;
        var longitude = 7.593889;

        function showMap() {
            if (typeof OpenLayers === 'object') {
                document.getElementById("locationPickerMap").style.display="block";

                var proj4326 = new OpenLayers.Projection("EPSG:4326");
                var projmerc = new OpenLayers.Projection("EPSG:900913");

                var mapZoom = 12;

                var markers = new OpenLayers.Layer.Markers( "Markers" );

                OpenLayers.Control.Click = OpenLayers.Class(OpenLayers.Control, {                
                    defaultHandlerOptions: {
                        'single': true,
                        'double': false,
                        'pixelTolerance': 0,
                        'stopSingle': false,
                        'stopDouble': false
                    },

                    initialize: function(options) {
                        this.handlerOptions = OpenLayers.Util.extend(
                            {}, this.defaultHandlerOptions
                        );
                        OpenLayers.Control.prototype.initialize.apply(
                            this, arguments
                        ); 
                        this.handler = new OpenLayers.Handler.Click(
                            this, {
                                'click': this.trigger
                            }, this.handlerOptions
                        );
                    }, 

                    trigger: function(e) {
                        var lonlat = osmMap.getLonLatFromPixel(e.xy);
                        lonlat1 = new OpenLayers.LonLat(lonlat.lon,lonlat.lat).transform(projmerc,proj4326);
                        document.getElementById("cbid.wizard.1._longitude").value=lonlat1.lon;
                        document.getElementById("cbid.wizard.1._latitude").value=lonlat1.lat;
                        markers.clearMarkers(); 
                        markers.addMarker(new OpenLayers.Marker(lonlat));

                        cbi_d_update("cbid.wizard.1._longitude");
                        cbi_d_update("cbid.wizard.1._latitude");
                    }
                });

                osmMap = new OpenLayers.Map("locationPickerMap", {
                    controls: [
                        new OpenLayers.Control.Navigation(),
                        new OpenLayers.Control.PanZoomBar(),
                        new OpenLayers.Control.MousePosition()
                    ],
                    maxExtent:
                    new OpenLayers.Bounds(-20037508.34,-20037508.34, 20037508.34, 20037508.34),
                    numZoomLevels: 18,
                    maxResolution: 156543,
                    units: 'm',
                    projection: projmerc,
                    displayProjection: proj4326
                } );

                var osmLayer = new OpenLayers.Layer.OSM("OpenStreetMap");
                osmMap.addLayer(osmLayer);

                osmMap.addLayer(markers);

                var temp_lon = longitude;
                var temp_lat = latitude;

                if(document.getElementById("cbid.wizard.1._longitude").value != "") temp_lon = document.getElementById("cbid.wizard.1._longitude").value;
                if(document.getElementById("cbid.wizard.1._latitude").value != "") temp_lat = document.getElementById("cbid.wizard.1._latitude").value;

                markers.addMarker(new OpenLayers.Marker(new OpenLayers.LonLat(temp_lon,temp_lat).transform(proj4326, projmerc)));

                var mapCenterPositionAsLonLat = new OpenLayers.LonLat(temp_lon, temp_lat);
                var mapCenterPositionAsMercator = mapCenterPositionAsLonLat.transform(proj4326, projmerc);

                osmMap.setCenter(mapCenterPositionAsMercator, mapZoom);

                var click = new OpenLayers.Control.Click();
                osmMap.addControl(click);
                click.activate();
            }else{
                setTimeout(showMap, 1000);
            }
        }

        var maindiv = document.getElementById("maincontainer");

        /* Append script via DOM to the end of the document - this prevents the browser
           from blocking the rendering if the OpenLayers-Server is unreachable
         */
        var newcontent = document.createElement('script');
        newcontent.setAttribute("type", "text/javascript");
        newcontent.setAttribute("src", "http://www.openlayers.org/api/OpenLayers.js");
        maindiv.appendChild(newcontent);

        setTimeout(showMap, 1000);
</script> 
    
    ]])

  local o

  o = s:option(cbi.Flag, "_location", "Knoten auf der Karte anzeigen")
  o.default = uci:get_first("gluon-node-info", "location", "share_location", o.disabled)
  o.rmempty = false

  o = s:option(cbi.Value, "_latitude", "Breitengrad")
  o.default = uci:get_first("gluon-node-info", "location", "latitude")
  o:depends("_location", "1")
  o.rmempty = false
  o.datatype = "float"
  o.description = "z.B. 53.873621"

  o = s:option(cbi.Value, "_longitude", "Längengrad")
  o.default = uci:get_first("gluon-node-info", "location", "longitude")
  o:depends("_location", "1")
  o.rmempty = false
  o.datatype = "float"
  o.description = "z.B. 10.689901"
end

function M.handle(data)
  local sname = uci:get_first("gluon-node-info", "location")

  uci:set("gluon-node-info", sname, "share_location", data._location)
  if data._location and data._latitude ~= nil and data._longitude ~= nil then
    uci:set("gluon-node-info", sname, "latitude", data._latitude)
    uci:set("gluon-node-info", sname, "longitude", data._longitude)
  end
  uci:save("gluon-node-info")
  uci:commit("gluon-node-info")
end

return M
