-- SolarMeter delete device.
local function delete(params)
	local storage = require("storage")
	local timer = require("timer")
	local core = require("core")

	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/delete_device").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	-- See if we know the device
	local device_id = params.deviceId
	if device_id then
		local d = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(device_id)
		if d then
			logger.info("Deleting device %1, ID %2, name %3 from Solar Meter plugin.", math.floor(d.id), device_id, d.name)
		else
			logger.info("Device %1 is not know to Solar Meter plugin.", device_id)
		end
		-- Remove device. The event device_removed will trigger cleanups needed.
		core.remove_device(device_id)
	else
		logger.warn("No device in parameter")
	end
end

delete(...)