-- Add solarman device
local function d_add(params)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solarman/add").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	-- Set device specific configuration
	local config = params.config

	-- Check configuration parameters
	assert(config.token, "RememberMe token missing, check SolarMeter.json configuration.")
	assert(config.device_id, "Device ID missing, check SolarMeter.json configuration.")
	assert(config.token ~= "", "RememberMe token empty, check SolarMeter.json configuration.")
	assert(config.device_id ~= "", "Device ID empty, check SolarMeter.json configuration.")

	-- Set device specific variables.
	local device = params.device
	local id = math.floor(device.id)
	if not storage.exists("WeeklyDaily"..id) then
		storage.set_table("WeeklyDaily"..id, {0,0,0,0,0,0,0})
	end
end

d_add(...)
