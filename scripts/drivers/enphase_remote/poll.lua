-- Enphase Remote poll handler
-- Update needed, so poll the device.
local function d_poll(device)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_remote/poll").setLevel(storage.get_number("log_level") or 99)

	local http = require("http")
	local URI = "https://api.enphaseenergy.com/api/v2/systems/%s/summary?key=%s&user_id=%s"
	
	logger.debug("device: %1", device)

	if device then
		local id = math.floor(device.id)
		local config = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_config")().get(id)
		if config then
			URI = URI:format(config.system_id, config.api_key, config.user_id)
			local hndlr = "HUB:"..PLUGIN.."/scripts/update_http"
			logger.debug("URL %1, handler %2", URI, hndlr)
			http.request { url = URI, handler = hndlr, user_data = device.device_id }
		else
			logger.err("Unable to get configuration for device %1.", id)
		end
	else
		logger.err("No device specified?")
	end
end

d_poll(...)
