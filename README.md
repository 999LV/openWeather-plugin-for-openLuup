openWeather plugin for openLuup

Version : 1.2
Date : Sept 22, 2016
Author : logread (LV999), contact by PM on http://forum.micasaverde.com/ 

Special thanks to amg0 for his support and advise
Acknowledgements to akbooer for developing the openLuup environement !

Introduction :
This plug-in is intended to run under the "openLuup" emulation of a Vera system. It should work on a "real" Vera, but has not been tested in that environment. It is intended to capture and monitor select weather data provided by Weather Underground www.weatherunderground.com under their general terms and conditions available on their website. It requires an API developer key that must be obtained from their website.

Changelog:
Version 1.0 2016-07-15 - first production version, installation via the AltUI/openLuup App Store
Version 1.1 2016-08-24 - rewrite for cleaner and faster code, but no new functionality
Version 1.2 2016-09-22 - added language parameter to fetch the WU data in another language than English (@korttoma suggestion)
			 added today and tomorrow forecast data (high/low temps, conditions and text forecast

Requires:
1.	A system running openLuup (or a Vera home automation controller, not tested) and the AltUI interface. For background, please see the http://forum.micasaverde.com/ forum.
2.	Lua libraries “socket.http” and “dkjson” installed (should already be in an openLuup environment (please refer to openLuup documentation)
3.	A valid API developer key from Weather Underground (please check their website for terms and conditions)
4.	A valid location (or personal weather station id) for Weather Underground lookup (please check their website for details)

Installation:
1.	Install from the AltUI App Store the “openWeather” app
2.	Select the “Variables” tab of the newly created “openWeather” device and edit the “ProviderKey” and “Location” variables to your needs (see requirements above). Also please edit the "Metric" variable to the value of 1 (metric units, default) or O (if you want to use US/Imperial units) and the "Language" variable to the two letters shortcut used by Weather Underground API (e.g. EN is English, FR is French, etc... as per https://www.wunderground.com/weather/api/d/docs?d=language-support)
3.	Reload the Luup engine…

Use:
You should now have 3 devices:
1.	“openWeather”: the main plugin device, with the configuration variables and some additional weather variables. Under the AltUI interface, the current weather/wind date will be displayed on in the device box and the device icon will reflect the current weather conditions.
2.	“oW Temperature”: a child device reporting the current temperature data and suitable for all usual actions/triggers in scenes for such a device.
3.	“oW Humidity”: a child device reporting the current relative humidity data and suitable for all usual actions/triggers in scenes for such a device.

Please note that only a very small subset of the weather data available from Weather Underground has been implemented in this beta version of openWeather. However, the code in “L_openWeather.lua” can be easily edited to add more features.

Notice:
This program is free software: you can redistribute it and/or modify it under the condition that it is for private or home usage and this whole comment is reproduced in the source code file.
Commercial utilisation is not authorized without the appropriate written agreement from the author. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
