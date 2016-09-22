_NAME = "openWeather"
_VERSION = "1.2"
_DESCRIPTION = "WU plugin for openLuup!!"
_AUTHOR = "logread (aka LV999)"

--[[

Version 1.0 2016-07-15 - first production version, installation via the AltUI/openLuup App Store
Version 1.1 2016-08-24 - major rewrite for cleaner and faster code, but no new functionality
Version 1.2 2016-09-22 - added language parameter to fetch the WU data in another language than English (@korttoma suggestion)
						 added today and tomorrow forecast data (high/low temps, conditions and text forecast

		Special thanks to amg0 and akbooer for their support and advise
		Acknowledgements to akbooer for developing the openLuup environement

This plug-in is intended to run under the "openLuup" emulation of a Vera system
It should work on a "real" Vera, but has not been tested in that environment.
It is intended to capture and monitor select weather data
provided by Weather Underground (www.weatherunderground.com) under their
general terms and conditions available on the website.
It requires an API developer key that must be obtained from the website.

This program is free software: you can redistribute it and/or modify
it under the condition that it is for private or home useage and
this whole comment is reproduced in the source code file.
Commercial utilisation is not authorized without the appropriate
written agreement from "logread", contact by PM on http://forum.micasaverde.com/
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--]]

local http = require("socket.http")
local json = require("dkjson")

local this_device
local child_temperature
local child_humidity

local SID_Weather = "urn:upnp-micasaverde-com:serviceId:Weather1"
local WU_urltemplate = "http://api.wunderground.com/api/%s/%s/lang:%s/q/%s.json"


local WU = {
	ProviderKey = "Enter your WU API key there",
	Location = "Enter your WU pws station or location here",
	Period = 1800,	-- data refresh interval in seconds
	Metric = 1,	-- 1 = metric units, 0 = US/Imperial
	Language = "EN", -- default language
	ProviderName = "WUI (Weather Underground)", -- added for reference to data source
	ProviderURL = "http://www.wunderground.com"
	}

local VariablesMap = {
	current_observation_temp_c = {serviceId = "urn:upnp-org:serviceId:TemperatureSensor1", variable = "CurrentTemperature"},
	current_observation_temp_f = {serviceId = "urn:upnp-org:serviceId:TemperatureSensor1", variable = "CurrentTemperature"},
	current_observation_relative_humidity = {serviceId = "urn:micasaverde-com:serviceId:HumiditySensor1", variable = "CurrentLevel", pattern = "%%"},
	current_observation_observation_epoch = {serviceId = SID_Weather, variable = "LastUpdate"},
	current_observation_weather = {serviceId = SID_Weather, variable = "Condition"},
	current_observation_wind_string = {serviceId = SID_Weather, variable = "WindCondition"},
	current_observation_icon_url = {serviceId = SID_Weather, variable = "IconUrl"},
	current_observation_icon = {serviceId = SID_Weather, variable = "ConditionGroup"},
	forecast_simpleforecast_forecastday_1_high_celsius = {serviceId = SID_Weather, variable = "TodayHighTemp"}, -- lua table indexes start at 1, not 0
	forecast_simpleforecast_forecastday_1_high_fahrenheit = {serviceId = SID_Weather, variable = "TodayHighTemp"},
	forecast_simpleforecast_forecastday_1_low_celsius = {serviceId = SID_Weather, variable = "TodayLowTemp"},
	forecast_simpleforecast_forecastday_1_low_fahrenheit = {serviceId = SID_Weather, variable = "TodayLowTemp"},
	forecast_simpleforecast_forecastday_1_conditions = {serviceId = SID_Weather, variable = "TodayConditions"},
	forecast_txt_forecast_forecastday_1_fcttext = {serviceId = SID_Weather, variable = "TodayForecast"},
	forecast_txt_forecast_forecastday_1_fcttext_metric = {serviceId = SID_Weather, variable = "TodayForecast"},
	forecast_simpleforecast_forecastday_2_high_celsius = {serviceId = SID_Weather, variable = "TomorrowHighTemp"}, -- lua table indexes start at 1, not 0
	forecast_simpleforecast_forecastday_2_high_fahrenheit = {serviceId = SID_Weather, variable = "TomorrowHighTemp"},
	forecast_simpleforecast_forecastday_2_low_celsius = {serviceId = SID_Weather, variable = "TomorrowLowTemp"},
	forecast_simpleforecast_forecastday_2_low_fahrenheit = {serviceId = SID_Weather, variable = "TomorrowLowTemp"},
	forecast_simpleforecast_forecastday_2_conditions = {serviceId = SID_Weather, variable = "TomorrowConditions"},
	forecast_txt_forecast_forecastday_2_fcttext = {serviceId = SID_Weather, variable = "TomorrowForecast"},
	forecast_txt_forecast_forecastday_2_fcttext_metric = {serviceId = SID_Weather, variable = "TomorrowForecast"}
	}

-- functions

local function nicelog(message)
	local display = "openWeather : %s"
	message = message or ""
	if type(message) == "table" then message = table.concat(message) end
	luup.log(string.format(display, message))
--	print(string.format(display, message))
end

local function setVar (service, name, value, device) -- credit to @akbooer
  device = device or this_device
  local old = luup.variable_get (service, name, device)
  if tostring(value) ~= old then
   luup.variable_set (service, name, value, device)
  end
end

function setvariables(key, value) -- process the WU data as needed
	if VariablesMap[key] then
		if VariablesMap[key].pattern then value = string.gsub(value, VariablesMap[key].pattern, "") end
		setVar(VariablesMap[key].serviceId, VariablesMap[key].variable, value)
		if VariablesMap[key].serviceId == "urn:upnp-org:serviceId:TemperatureSensor1" then -- we update the child device as well
			setVar(VariablesMap[key].serviceId, VariablesMap[key].variable, value, child_temperature)
		end
		if VariablesMap[key].serviceId == "urn:micasaverde-com:serviceId:HumiditySensor1" then -- we update the child device as well
			setVar(VariablesMap[key].serviceId, VariablesMap[key].variable, value, child_humidity)
		end
--		nicelog({VariablesMap[key].serviceId," - ", VariablesMap[key].variable, " = ", value})
	end
end

function extractloop(datatable, keystring)
	local tempstr, separator
	keystring = keystring or ""
	for tkey, value in pairs(datatable) do
		if keystring ~= "" then separator = "_" else separator = "" end
		tempstr = table.concat{keystring, separator, tkey}
		if type(value) == "table" then -- one level up in the data hierarchy -> recursive call
			extractloop(value, tempstr)
		else
			setvariables(tempstr, value)
		end
	end
end

function WU_GetData(category) -- call the WU API with our key and location parameters and decode/parse the weather data
	local url = string.format(WU_urltemplate, WU.ProviderKey, category, WU.Language, WU.Location)
	nicelog({"calling WU with url = ", url})
	local wdata, retcode = http.request(url)
	local err = (retcode ~=200)
	if err then -- something wrong happpened (website down, wrong key or location)
		wdata = nil -- to do: proper error handling
		nicelog({"WU call failed with http code =  ", tostring(retcode)})
	else
		wdata, err = json.decode(wdata)
		if not (err == 225) then extractloop(wdata) else nicelog({"WU json decode error = ", tostring(err)}) end
	end
	return err
end

function check_param_updates() -- check if device parameters are current
local tvalue
	for key, value in pairs(WU) do
		tvalue = luup.variable_get(SID_Weather, key, this_device) or ""
		if tvalue == "" then luup.variable_set(SID_Weather, key, value, this_device) -- device newly created... need to initialize variables
		elseif tvalue ~= value then WU[key] = tvalue end
	end
end

function Weather_delay_callback() -- poll Weather Undergound for changes
	check_param_updates()
	WU_GetData("conditions") -- get current conditions
	WU_GetData("forecast") -- get forecast conditions
	luup.call_delay ("Weather_delay_callback", WU["Period"])
end

function createchildren()
	local children = luup.chdev.start(this_device)
	luup.chdev.append(	this_device, children, "OWT", "oW Temperature", "urn:schemas-micasaverde-com:device:TemperatureSensor:1",
						"D_TemperatureSensor1.xml", "", "", true)
	luup.chdev.append(	this_device, children, "OWH", "oW Humidity", "urn:schemas-micasaverde-com:device:HumiditySensor:1",
						"D_HumiditySensor1.xml", "", "", true)
	luup.chdev.sync(this_device, children)
	child_temperature = nil
	child_humidity = nil
	for devNo, dev in pairs (luup.devices) do -- check if both children exist
		if dev.device_num_parent == this_device then
			if dev.id == "OWT" then child_temperature = devNo
			elseif dev.id == "OWH" then child_humidity = devNo end
		end
    end
end

function init(lul_device)
	this_device = lul_device
	nicelog("device startup")
	if luup.attr_get("TemperatureFormat") == "F" then -- localize for Farenheit or Celsius based on openLuup setup
		VariablesMap.current_observation_temp_c = nil
		VariablesMap.forecast_simpleforecast_forecastday_1_high_celsius = nil
		VariablesMap.forecast_simpleforecast_forecastday_1_low_celsius = nil
		VariablesMap.forecast_simpleforecast_forecastday_2_high_celsius = nil
		VariablesMap.forecast_simpleforecast_forecastday_2_low_celsius = nil
	else
		VariablesMap.current_observation_temp_f = nil
		VariablesMap.forecast_simpleforecast_forecastday_1_high_fahrenheit = nil
		VariablesMap.forecast_simpleforecast_forecastday_1_low_fahrenheit = nil
		VariablesMap.forecast_simpleforecast_forecastday_2_high_fahrenheit = nil
		VariablesMap.forecast_simpleforecast_forecastday_2_low_fahrenheit = nil
	end
	if WU.Metric == 1 then -- localize for Metric or US/Imperial based on user defined device variable "Metric"
		VariablesMap.forecast_txt_forecast_forecastday_1_fcttext = nil
		VariablesMap.forecast_txt_forecast_forecastday_2_fcttext = nil
	else
		VariablesMap.forecast_txt_forecast_forecastday_1_fcttext_metric = nil
		VariablesMap.forecast_txt_forecast_forecastday_2_fcttext_metric = nil
	end
	createchildren(this_device)
	Weather_delay_callback()
	nicelog("device started")
	return true, "OK", _NAME
end
