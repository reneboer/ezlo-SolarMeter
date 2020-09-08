-- SolarMeter delete device.
local function delete(params)
	local storage = require("storage")
	local timer = require("timer")
	local core = require("core")

	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/delete_device").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	-- See if called from startup.lua or forceRemoveDeviceCommand script event.
	local device_id = nil
	if type(params) == "string" then
		device_id = params
	else
		device_id = params.deviceId
	end
	if device_id then
		local device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(device_id)
		if device then
			local id = math.floor(device.id)
			logger.info("Deleting device %1, ID %2, name %3 from Solar Meter plugin.", id, device_id, device.name)
			-- Run device specific stop routine.
			local stop = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/stop")
			if stop then 
				stop(device)
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
			
			-- Run device specific remove routine
			local rem = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/remove")
			if rem then rem(device) end

			-- Remove mappings from storage
			storage.delete("SM_D_"..id)
			storage.delete("SM_C_"..id)
			storage.delete("SM_M_"..params._id)
		else
			logger.info("Device %1 is not know to Solar Meter plugin.", device_id)
		end
		-- Remove device from hub. 
		core.remove_device(device_id)
	else
		logger.warn("No device in parameter")
	end
end

delete(...)