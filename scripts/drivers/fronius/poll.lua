-- Enphase Fronius handler
-- Update needed, so poll the device.
local function d_poll(device)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/fronius/poll").setLevel(storage.get_number("log_level") or 99)

	local http = require("http")
	local URI = "http://%s/solar_api/v1/GetInverterRealtimeData.cgi?Scope=Device&DeviceId=%s&DataCollection=CommonInverterData"
	
	logger.debug("device: %1", device)

	-- Get device details and send http request for data. update script will handle response.
	if device then
		local cnf = device.config
		URI = URI:format(cnf.ip,cnf.device_id)
		local hndlr = "HUB:"..PLUGIN.."/scripts/update_http"
		logger.debug("URL %1, handler %2", URI, hndlr)
		http.request { url = URI, handler = hndlr, user_data = device.device_id }
	else
		logger.err("No device specified?")
	end
end

d_poll(...)
