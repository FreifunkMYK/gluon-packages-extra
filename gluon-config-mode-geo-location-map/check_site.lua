if need_table('config_mode', nil, false) and need_table('config_mode.geo_location_map', nil, false) then
  need_boolean('config_mode.geo_location_map.show_altitude', false)
  need_boolean('config_mode.geo_location_map.show_map', true)
end
