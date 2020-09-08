-- Update values with details from device specific update
local function update(params)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/update_http").setLevel(storage.get_number("log_level") or 99)

--	logger.debug("params=%1",params)

	local ed = params.data
	local device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(ed.user_data)
	if not device then
		logger.crit("Cannot get device details for device %1 from storage.", ed.user_data)
		return
	end
	local id = math.floor(device.id)
	local lastupdate = storage.get_number("LastRefresh"..id) or 0
	if params.event == "http_data_received" then
		if ed.code == 200 then
			local handler = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/update")
			if handler then
				local res = handler(device, ed.data)
				logger.debug("result=%1",res)
				if res then
					-- See if we have updated values, else ignore.
					if lastupdate ~= res.timestamp then
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
						if res.WeekKWH ~= -1 then 
							storage.set_number("WeekKWH"..id, res.WeekKWH) 
							core.update_item_value(device.kwh_week_itemId, {value = res.WeekKWH, scale = "kilo_watt_hour"})
						end
						if res.MonthKWH ~= -1 then 
							storage.set_number("MonthKWH"..id, res.MonthKWH) 
							core.update_item_value(device.kwh_month_itemId, {value = res.MonthKWH, scale = "kilo_watt_hour"})
						end
						if res.YearKWH ~= -1 then 
							storage.set_number("YearKWH"..id, res.YearKWH) 
							core.update_item_value(device.kwh_year_itemId, {value = res.YearKWH, scale = "kilo_watt_hour"})
						end
						if res.LifeKWH ~= -1 then 
							storage.set_number("DayKWH"..id, res.LifeKWH) 
							core.update_item_value(device.kwh_life_itemId, {value = res.LifeKWH, scale = "kilo_watt_hour"})
						end
						if res.timestamp ~= -1 then 
							storage.set_number("LastRefresh"..id, res.timestamp)
							lastupdate = res.timestamp
						end
					end
				else
					logger.debug("Device update script for %1 has no results.", device.name)
				end
			else
				logger.crit("Update script for device %1 cannot be loaded.", device.name)
			end
		else
			logger.err("We got data, but not what we expected :-). HTTP return code %1", ed.code)
		end
	
		-- See if device has dynamic polling. If so set timer for next poll.
		if device.poll_dynamic then
			local timer = require("timer")
			local handler = loadfile("HUB:"..PLUGIN.."/scripts/drivers/"..device.path.."/interval")
			local interval = device.poll_interval or 900
			if handler then
				local int = handler(device, lastupdate, ed.code)
				if int > 0 then interval = int end
			else
				logger.crit("Interval script for device %1 cannot be loaded. Using standard interval", device.name)
			end
			local timer_id = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_timer_id")().get(device.id)
			logger.debug("Setting dynamic timer %1 to poll in %2 sec.", timer_id, interval)
			timer.set_timeout_with_id(interval * 1000, timer_id, "HUB:"..PLUGIN.."/scripts/poll", {device_id = device.device_id})
		end
	end
end

update(...)