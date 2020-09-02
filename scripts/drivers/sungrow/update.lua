-- SolarMeter sungrow http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/sungrow/update").setLevel(storage.get_number("log_level") or 99)
	
	local function GetAsNumber(value)
		if type(value) == "number" then return value end
		local nv = tonumber(value)
		return (nv or 0)
	end

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
		local id = math.floor(device.id)
		watts = math.floor(GetAsNumber(retData.power) * 1000)
		DayKWH = GetAsNumber(retData.todayEnergy)
		if DayKWH ~= -1 then
			WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, id)
			MonthKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/month_total")().total(DayKWH, id)
			if MonthKWH ~= -1 then
				YearKWH =loadfile("HUB:"..PLUGIN.."/scripts/utils/year_total")().total(MonthKWH, id)
			end
		end
		-- Only update time stamp if watts are updated.
		if watts == storage.get_number("Watts"..id) then
			ts = storage.get_number("LastRefresh"..id)
			if ts == 0 then ts = os.time() end
		end
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)
