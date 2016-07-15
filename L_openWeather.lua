_NAME = "openWeather"
_VERSION = "2016.07.15"
_DESCRIPTION = "WU plugin for openLuup!!"
_AUTHOR = "logread (aka LV999)"

--[[

		Version 1.0 (first production version)
		changelog:	- code optimization (w/ recursive parsing of WU data table)
					- installation via the AltUI/openLuup App Store

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

local WU = {}
WU["ProviderKey"] = "Enter your WU API key there"
WU["Location"] = "Enter your WU pws station or location here"
WU["Period"] = 1800	-- data refresh interval in seconds
WU["Metric"] = 1	-- 1 = metric units, 0 = US/Imperial, not yet used
WU["ProviderName"] = "WUI (Weather Underground)" -- added for reference to data source
WU["ProviderURL"] = "http://www.wunderground.com"

local Str_Obs = "current_observation." -- the "root" key of the useful part of the data table from WU
local Str_Temperature = "temp_c" 	-- the name of the raw variable name for the device temp
									-- automatically changed in init() to "temp_f" for Farenheit based on user_data attribute
local Str_Humidity = "relative_humidity"  -- the name of the raw variable name for the device humidity
local Str_LastUpdate = "observation_epoch" -- the unix timestamp of the last WU observation
local Str_Condition = "weather" -- the current conditions reported
local Str_WindCondition = "wind_string" -- the wind string (to do : localize units MPH v.s. KPH)
local Str_IconURL = "icon_url" -- the url pointing to the current weather ico (to do : display in UI device interface)
local Str_ConditionGroup = "icon" -- the condition to be used to fetch the icon and display it with AltUI

local SID_Weather = "urn:upnp-micasaverde-com:serviceId:Weather1"

-- the following table lists all variables we want to be reported in the plugin device
local dvars = {}
dvars["Temperature"] = {"urn:upnp-org:serviceId:TemperatureSensor1", "CurrentTemperature", "0"}
dvars["Humidity"] = {"urn:micasaverde-com:serviceId:HumiditySensor1", "CurrentLevel", "0"}
dvars["LastUpdate"] = {SID_Weather, "LastUpdate", "1456988176"}
dvars["Condition"] = {SID_Weather, "Condition", ""}
dvars["ConditionGroup"] = {SID_Weather, "ConditionGroup", ""}
dvars["WindCondition"] = {SID_Weather, "WindCondition", ""}
dvars["IconUrl"] = {SID_Weather, "IconUrl", ""}

-- children devices
local child_temperature
local child_humidity

-- functions

function setvariables(key, value) -- extract the variables we want for our device from the WU data
	if key == Str_Obs .. Str_Temperature then dvars["Temperature"][3] = value
	elseif key == Str_Obs .. Str_Humidity then dvars["Humidity"][3] = string.gsub(value, "%%", "") -- !!! need to trim the "%" from the WU data
	elseif key == Str_Obs .. Str_LastUpdate then dvars["LastUpdate"][3] = value
	elseif key == Str_Obs .. Str_Condition then dvars["Condition"][3] = value
	elseif key == Str_Obs .. Str_ConditionGroup then dvars["ConditionGroup"][3] = value
	elseif key == Str_Obs .. Str_WindCondition then dvars["WindCondition"][3] = value
	elseif key == Str_Obs .. Str_IconURL then dvars["IconUrl"][3] = value
--	uncomment line below if all data from WU are desired as device variables (50+ !!!)
--	else dvars[key] = {SID_Weather, key, value}
	end
end

function extractloop(datatable, keystring)
	local tempstr
	keystring = keystring or ""
	for tkey, value in pairs(datatable) do
		if keystring == "" then
			tempstr = tkey
		else
			tempstr = keystring .. "." .. tkey
		end
		if type(value) == "table" then
			extractloop(value, tempstr)
		else
			setvariables(tempstr, value)
		end
	end
end

function WU_GetData(category) -- call the WU API with our key and location parameters and decode/parse the weather data
-- get current conditions
	local url = "http://api.wunderground.com/api/" .. WU["ProviderKey"] .. "/" ..category .. "/q/" .. WU["Location"] .. ".json"
	local wdata, retcode = http.request(url)
	local err = (retcode ~=200)
	if err then -- something wrong happpened (website down, wrong key or location)
		wdata = nil -- to do: proper error handling
	else
		wdata, err = json.decode(wdata)
		if not (err == 225) then extractloop(wdata) end
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
	local nodata = WU_GetData("conditions")
	for key, value in pairs(dvars) do
		if luup.variable_get(value[1], value[2], this_device) ~= value[3] then -- only update if there is a change... better for watches
			luup.variable_set(value[1], value[2], value[3], this_device)
			if key == "Temperature" then
				luup.variable_set(value[1], value[2], value[3], child_temperature) -- update child temperature
			elseif key == "Humidity" then
				luup.variable_set(value[1], value[2], value[3], child_humidity) end -- update child humidity
		end
	end
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
	if luup.attr_get("TemperatureFormat") == "F" then Str_Temperature = "temp_f" end -- localize for Farenheit
	createchildren(this_device)
	Weather_delay_callback()
	return true, "OK", _NAME
end