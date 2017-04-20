# gluon-config-mode-geo-location-map

This module replaces the original ``gluon-config-mode-geo-location`` and adds an OpenLayers based visual map for choosing the nodes coordinates if the configuring client is connected to the internet. OpenLayers can be loaded from a CDN or hosted on your communities site.

## Configuration
First include the code into your local module repository and add ``gluon-config-mode-geo-location-map`` to ``GLUON_SITE_PACKAGES`` in ``site.mk``, also it is advised to remove the original ``gluon-config-mode-geo-location`` to avoid duplicate fields. Now add the following parameters to your ``site.conf``:

      config_mode = {
        geo_location_map = {
          show_map = true,
          map_lon = 50.356667,
          map_lat = 7.593889,
          olurl = 'http://firmware.freifunk-myk.de/.static/ol/OpenLayers.js',
          show_altitude = false,
        },
      }

The parameter ``show_map`` is mandatory, ``olurl``, map_lon, map_lat and ``show_altitude`` can be omitted, in this case the standard CDN is used, the map centered to berlin and the altitude fields shown.

Again: The map will only be displayed if the client used for configuration is able to connect to the internet

## Credits
* Florian Knodt of Freifunk-MYK

## Notes
* On PCs not connected to the internet it might trigger an error or look like the page hasn't finished loading
* Currently a pre-[minified](https://jscompress.com/) version of osm.js is supplied in the files/-folder. The original code can be found in jssrc/

## Todo

* Use internal js-minification
* Port to current OpenLayers Version
  * Note: OL3 doesn't produce valid XML and cannot be used without modification :(
* Allow for alternate tile servers and map sources 
