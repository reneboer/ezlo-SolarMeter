-- Solar Meter generic poll event handler
local function poll(params)
	local storage = require("storage")
	local timer = require("timer")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/poll").setLevel(storage.get_number("log_level") or 99)

	logger.debug("params: %1", params)

	-- To-do See if it is night time and need to schedule next poll to tomorrow morning
	local device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(params.device_id)
	logger.debug("device: %1", device)
	if device then
		local interval = device.poll_interval or 900
		local timer_id = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_timer_id")().get(device.id)
		-- Call device timer calculation script if available
		local handler = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/interval")
		if handler then
			interval = handler(device)
		else
			logger.debug("Device does not have interval script.")
		end
		logger.debug("Setting timer %1 to poll in %2 sec.", timer_id, interval)
		timer.set_timeout_with_id(interval * 1000, timer_id, "HUB:"..PLUGIN.."/scripts/poll", {device_id = device.device_id})
	
		-- Call device poll script
		local handler = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/poll")
		if handler then
			handler(device)
		else
			logger.crit("Device poll script cannot be loaded.")
		end
	else
		logger.err("Unable to find device details for %1.",(params.device_id or "-missing-"))
	end
end

poll(...)