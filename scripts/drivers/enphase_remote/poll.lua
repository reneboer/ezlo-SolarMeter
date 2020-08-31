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
		-- We do not poll at night time to avoid hitting API limit. For now only looks at hub location.
		local location = core.get_location()
		local isnight = loadfile("HUB:"..PLUGIN.."/scripts/utils/sun")().isnight(location.latitude, location.longitude) or false
		if isnight and (storage.get_number("Watts"..id) == 0) then
			logger.info("Skipping polling at night")
		else	
			local cnf = device.config
			URI = URI:format(cnf.system_id, cnf.api_key, cnf.user_id)
			local hndlr = "HUB:"..PLUGIN.."/scripts/update_http"
			logger.debug("URL %1, handler %2", URI, hndlr)
			http.request { url = URI, handler = hndlr, user_data = device.device_id }
		end	
	else
		logger.err("No device specified?")
	end
end

d_poll(...)
