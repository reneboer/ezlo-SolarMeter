-- SolarMeter teardown script. Called when device is stopped.
local function teardown(params)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/teardown").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters: %1", params)

	local function stop_devices(max_dev)
		local timer = require("timer")
		-- Find any devices we may have running.
		for id = 1, max_dev do
			local device_id = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device_id")().get(id)
			if device_id then
				local device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(device_id)
				if device then
					-- Run device specific stop routine if required.
					local stop = loadfile( "HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/stop" )
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
				else
					logger.warn("No device storage found for device id %1.", device_id)
				end
			end
		end
	end

	-- Stop any devices and un-subscribe event handler
	stop_devices(20)	-- Assume max 20 devices defined
	core.unsubscribe("HUB:"..PLUGIN.."/scripts/events/handler")
end

teardown(...)