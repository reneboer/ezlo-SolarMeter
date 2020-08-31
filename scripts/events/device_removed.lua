-- SolarMeter device_removed event.
local params = ...
local storage = require("storage")
local timer = require("timer")
local PLUGIN = storage.get_string("PLUGIN")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/events/device_removed").setLevel(storage.get_number("log_level") or 99)

logger.debug("parameters: %1", params)
local dev = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(params._id)
if dev then
	local id = math.floor(dev.id)
	logger.debug("Stopping device and removing storage details for meter device %1", id)
	-- Run device specific stop routine.
	local stop = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..dev.path.."/stop")
	if stop then 
		stop({device = device})
	else
		-- Just stop the timer. Works for most cases.
		local timer_id = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_timer_id")().get(id)
		if timer.exists(timer_id) then
			logger.debug("Stopping timer %1 for device %2.", timer_id, device.name)
			timer.cancel(timer_id)
		end	
	end
	storage.delete("Watts"..id)
	storage.delete("DayKWH"..id)
	storage.delete("WeekKWH"..id)
	storage.delete("MonthKWH"..id)
	storage.delete("YearKWH"..id)
	storage.delete("LifeKWH"..id)
	storage.delete("LastRefresh"..id)
	-- Run device specific remove routing
	local rem = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..dev.path.."/remove")
	if rem then rem({device = dev}) end

	-- Remove mappings
	storage.delete("SM_D_"..id)
	storage.delete("SM_M_"..params._id)
else
	logger.info("Device %1 is not a known SolarMeter device.", params._id)
end	
