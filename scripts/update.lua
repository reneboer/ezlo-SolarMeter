-- Update values with details from device specific update
local function update(params)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/update").setLevel(storage.get_number("log_level") or 99)

	logger.debug("params=%1",params)

	local device = params.device
	local id = math.floor(device.id)

	-- Set values in storage
	if params.watts ~= -1 then 
		storage.set_number("Watts"..id, params.watts)
		core.update_item_value(device.watt_itemId, {value = params.watts, scale = "watt"})
	end
	if params.DayKWH ~= -1 then
		local kwh = math.floor(params.DayKWH *1000)/1000
		storage.set_number("KWH"..id, kwh)
		storage.set_number("DayKWH"..id, params.DayKWH) 
		core.update_item_value(device.kwh_itemId, {value = kwh, scale = "kilo_watt_hour"})
	end
	if params.WeekKWH ~= -1 then storage.set_number("WeekKWH"..id, params.WeekKWH) end
	if params.MonthKWH ~= -1 then storage.set_number("MonthKWH"..id, params.MonthKWH) end
	if params.YearKWH ~= -1 then storage.set_number("YearKWH"..id, params.YearKWH) end
	if params.LifeKWH ~= -1 then storage.set_number("DayKWH"..id, params.LifeKWH) end
	if params.timestamp ~= -1 then storage.set_number("LastRefresh"..id, params.timestamp) end
	--storage.set_string("LastUpdate", os.date("%H:%M:%S %d", ts))
end

update(...)