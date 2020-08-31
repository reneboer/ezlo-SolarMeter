-- SolarMeter device_added event.
local params = ...
local storage = require("storage")
local PLUGIN = storage.get_string("PLUGIN")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/events/device_added").setLevel(storage.get_number("log_level") or 99)

logger.debug("parameters: %1", params)
--[[
local id = params._id)
if id then
	logger.debug("Creating storage variables for meter device %1", id)
	storage.set_number(id..".Watts")
	storage.set_number(id..".DayKWH")
	storage.set_number(id..".WeekKWH")
	storage.set_number(id..".MonthKWH")
	storage.set_number(id..".YearKWH")
	storage.set_number(id..".LifeKWH")
	storage.set_number(id..".LastRefresh")
else
	logger.err("Device missing.")
end	
]]
