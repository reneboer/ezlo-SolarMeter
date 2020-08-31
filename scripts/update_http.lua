-- Update values with details from device specific update
local function update(params)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/update_http").setLevel(storage.get_number("log_level") or 99)

--	logger.debug("params=%1",params)

	local ed = params.data
	if params.event == "http_data_received" then
		if ed.code == 200 then
			local device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(ed.user_data)
			local handler = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/update")
			if handler then
				local res = handler(device, ed.data)
				logger.debug("result=%1",res)
				if res then
					local id = math.floor(device.id)

					-- Set values in storage
					if res.watts ~= -1 then 
						storage.set_number("Watts"..id, res.watts)
						core.update_item_value(device.watt_itemId, {value = res.watts, scale = "watt"})
					end
					if res.DayKWH ~= -1 then
						local kwh = math.floor(res.DayKWH *1000)/1000
						storage.set_number("KWH"..id, kwh)
						storage.set_number("DayKWH"..id, res.DayKWH) 
						core.update_item_value(device.kwh_itemId, {value = kwh, scale = "kilo_watt_hour"})
					end
					if res.WeekKWH ~= -1 then storage.set_number("WeekKWH"..id, res.WeekKWH) end
					if res.MonthKWH ~= -1 then storage.set_number("MonthKWH"..id, res.MonthKWH) end
					if res.YearKWH ~= -1 then storage.set_number("YearKWH"..id, res.YearKWH) end
					if res.LifeKWH ~= -1 then storage.set_number("DayKWH"..id, res.LifeKWH) end
					if res.timestamp ~= -1 then storage.set_number("LastRefresh"..id, res.timestamp) end
					--storage.set_string("LastUpdate", os.date("%H:%M:%S %d", ts))
				else
					logger.debug("Device update script for %1 has no results.", device.name)
				end
			else
				logger.crit("Update script for device %1 cannot be loaded.", device.name)
			end
		else
			logger.err("We got data, but not what we expected :-). HTTP return code %1", ed.code)
		end
	end
end

update(...)