if need_table('config_mode', nil, false) and need_table('config_mode.qrcode', nil, false) then
  need_boolean('config_mode.qrcode.show_qrcode', true)
  need_string('config_mode.qrcode.url_prefix')
  need_string('config_mode.qrcode.url_suffix', '')
end
