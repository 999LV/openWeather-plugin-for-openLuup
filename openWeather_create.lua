do
  local dev = luup.create_device ('', "OW", "openWeather", "D_openWeather.xml", "I_openWeather.xml")
  print("openWeather device created... device number = " .. dev)
  print("please make sure to immediately edit the 'ProviderKey' and 'Location' device variables with valid data")
  print("and reload the Luup engine !")
end
