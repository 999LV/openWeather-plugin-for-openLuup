openWeather plugin for openLuup

Version : 1.4 
Date : November 14, 2016 
Author : logread (LV999), contact by PM on http://forum.micasaverde.com/ 

Special thanks to amg0 for his support and advise 
Acknowledgements to akbooer for developing the openLuup environement ! 

Introduction : 
This plug-in is intended to run under the "openLuup" emulation of a Vera system. It should work on a "real" Vera, but has not been tested in that environment. It is intended to capture and monitor select weather data provided by Weather Underground www.weatherunderground.com under their general terms and conditions available on their website. It requires an API developer key that must be obtained from their website. 

Requires: 
1.	A system running openLuup (or a Vera home automation controller, not tested) and the AltUI interface. For background, please see the http://forum.micasaverde.com/ forum. 
2.	Lua libraries “socket.http” and “dkjson” installed (should already be in an openLuup environment (please refer to openLuup documentation) 
3.	A valid API developer key from Weather Underground (please check their website for terms and conditions) 
4.	A valid location (or personal weather station id) for Weather Underground lookup (please check their website for details) 

Installation: 
1.	Install from the AltUI App Store the “openWeather” app 
2.	Select the “Variables” tab of the newly created “openWeather” device and edit the “ProviderKey” and “Location” variables to your needs (see requirements above).
3.	Edit additional configuration variables as needed. See the “Configuration” section below for a description of these).
4.	Reload the Luup engine… 

Use: 
You should now have 3 devices: 
1.	“openWeather”: the main plugin device, with the configuration variables and some additional weather variables. Under the AltUI interface, the current weather/wind date will be displayed on in the device box and the device icon will reflect the current weather conditions. 
2.	“oW Temperature”: a child device reporting the current temperature data and suitable for all usual actions/triggers in scenes for such a device. 
3.	“oW Humidity”: a child device reporting the current relative humidity data and suitable for all usual actions/triggers in scenes for such a device. 

These 3 devices can be renamed as you wish using the AltUI interface.

Configuration:
The plugin configuration parameters are stored in the following device variables of the plugin:

ProviderKey	valid API developer key from Weather Underground
Location	valid location (or personal weather station id) for Weather Underground lookup. See “location query examples” in the appendix section below.
Period	plugin data refresh interval in seconds (default is 1800 i.e. 1/2h)
Metric	1 = metric units (default), 0 = US/Imperial
Language	a valid Weather Underground language selector (default is EN). Please see https://www.wunderground.com/weather/api/d/docs?d=language-support
AllowEstimated	if 1 then WU estimates are allowed when selected weather station is not available (default), if 0 then WU estimated data is ignored.

The plugin will automatically switch display of temperatures between Celsius and Fahrenheit based of the Vera or openLuup system parameters.

Please note that only a very small subset of the weather data available from Weather Underground has been implemented in this beta version of openWeather. However, the code in “L_openWeather.lua” can be easily edited to add more features. 

Notice: 
This program is free software: you can redistribute it and/or modify it under the condition that it is for private or home usage and this whole comment is reproduced in the source code file. 
Commercial utilisation is not authorized without the appropriate written agreement from the author. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Appendix:

Location query examples:
CA/San_Francisco	US state/city
60290	US zipcode
Australia/Sydney	country/city
37.8,-122.4	latitude,longitude
KJFK	airport code
pws:KCASANFR70	PWS id
autoip	AutoIP address location
autoip.json?geo_ip=38.102.136.138	specific IP address location

