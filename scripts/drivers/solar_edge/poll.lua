-- solar edge poll handler
-- Update needed, so poll the device.
local function d_poll(device)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solar_edge/poll").setLevel(storage.get_number("log_level") or 99)

	local http = require("http")
	local URI = "https://monitoringapi.solaredge.com/site/%s/overview.json?api_key=%s"
	
	logger.debug("device: %1", device)

	-- Get device details and send http request for data. update script will handle response.
	if device then
		local cnf = device.config
		URI = URI:format(cnf.system_id, cnf.api_key)
		local hndlr = "HUB:"..PLUGIN.."/scripts/update_http"
		logger.debug("Envoy Local URL %1, handler %2", URI, hndlr)
		http.request { url = URI, handler = hndlr, user_data = device.device_id }
	else
		logger.err("No device specified?")
	end
end

d_poll(...)