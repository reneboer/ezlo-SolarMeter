-- Add Enphase Remote device
local function d_add(params)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_remote/add").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	-- Set device specific configuration
	local config = params.config

	-- Check configuration parameters
	assert(config.api_key, "API key missing, check SolarMeter.json configuration.")
	assert(config.user_id, "User ID missing, check SolarMeter.json configuration.")
	assert(config.system_id, "System ID missing, check SolarMeter.json configuration.")

	-- Set device specific variables.
	local device = params.device
	local id = math.floor(device.id)
	if not storage.exists("WeeklyDaily"..id) then
		storage.set_table("WeeklyDaily"..id, {0,0,0,0,0,0,0})
	end
	if not storage.exists("MonthlyDaily"..id) then
		storage.set_table("MonthlyDaily"..id, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
	end
	if not storage.exists("YearlyMonthly"..id) then
		storage.set_table("YearlyMonthly"..id, {0,0,0,0,0,0,0,0,0,0,0,0})
	end
end

d_add(...)

