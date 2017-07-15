if need_table('config_mode', nil, false) and need_table('config_mode.geo_location_map', nil, false) then
  need_boolean('config_mode.geo_location_map.show_altitude', false)
  need_boolean('config_mode.geo_location_map.show_map', true)
  need_string('config_mode.geo_location_map.olurl', false)
  need_number('config_mode.geo_location_map.map_lon', false)
  need_number('config_mode.geo_location_map.map_lat', false)
end
