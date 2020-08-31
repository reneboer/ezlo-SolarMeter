-- Add solar edge device
local function d_add(params)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solar_edge/add").setLevel(storage.get_number("log_level") or 99)

	logger.debug("parameters %1", params)
	
	-- Check device specific configuration
	local config = params.config
	assert(config.api_key, "API Key missing, check SolarMeter.json configuration.")

	-- Set device specific variables.
	local device = params.device
	local id = math.floor(device.id)
	if not storage.exists("WeeklyDaily"..id) then
		storage.set_table("WeeklyDaily"..id, {0,0,0,0,0,0,0})
	end
end

d_add(...)