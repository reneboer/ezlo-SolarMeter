-- solarman poll handler
-- Update needed, so poll the device.
local function d_poll(device)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solarman/poll").setLevel(storage.get_number("log_level") or 99)

	local http = require("http")
	local URI = "https://home.solarman.cn/cpro/device/inverter/goDetailAjax.json"
	
	logger.debug("device: %1", device)

	-- Get device details and send http request for data. update script will handle response.
	if device then
		local cnf = device.config
		local request_body = "deviceId=" .. cnf.device_id
		local headers = {
			['origin'] = 'https://home.solarman.cn',
			['referer'] = 'https://home.solarman.cn/device/inverter/view.html?v=2.2.9.2&deviceId='..cnf.device_id,
			['accept'] = 'application/json',
			['content-type'] = 'application/x-www-form-urlencoded',
			['accept-encoding'] = 'identity',
			['connection'] = 'keep-alive',
			['content-length'] = string.len(request_body),
			['cookie'] = 'language=2; autoLogin=on; Language=en_US; rememberMe=' .. cnf.token
		}
		URI = URI:format(device.config.ip)
		local hndlr = "HUB:"..PLUGIN.."/scripts/update_http"
		logger.debug("Envoy Local URL %1, handler %2", URI, hndlr)
		http.request { url = URI, headers = headers, type = "POST", data = request_body, handler = hndlr, user_data = device.device_id }
	else
		logger.err("No device specified?")
	end
end

d_poll(...)