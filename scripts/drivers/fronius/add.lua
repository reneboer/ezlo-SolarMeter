-- Add Fronius device
local function d_add(params)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/fronius/add").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	-- Check device specific configuration
	local config = params.config
	local ip = string.match(config.ip, '^(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)')
	assert(ip, "IP address missing/incorrect, check SolarMeter.json configuration.")
	assert(config.device_id, "Device ID missing, check SolarMeter.json configuration.")
	assert(config.device_id ~= "", "Device ID empty, check SolarMeter.json configuration.")

	-- Set device specific variables.
	local device = params.device
	local id = math.floor(device.id)
	if not storage.exists("WeeklyDaily"..id) then
		storage.set_table("WeeklyDaily"..id, {0,0,0,0,0,0,0})
	end
	if not storage.exists("MonthlyDaily"..id) then
		storage.set_table("MonthlyDaily"..id, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
	end
	return device
end

d_add(...)
