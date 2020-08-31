-- SolarMeter enphase remote http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_remote/update").setLevel(storage.get_number("log_level") or 99)
	
	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
		local id = math.floor(device.id)
		watts = retData.current_power or -1
		DayKWH = (retData.energy_today or -1000)/1000
		LifeKWH = (retData.energy_lifetime or -1000)/1000
		if DayKWH ~= -1 then
			WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, id)
			MonthKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/month_total")().total(DayKWH, id)
			if MonthKWH ~= -1 then
				YearKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/year_total")().total(MonthKWH, id)
			end	
		end
		ts = retData.last_report_at
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.err("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)
