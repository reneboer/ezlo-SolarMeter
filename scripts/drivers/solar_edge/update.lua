-- SolarMeter solar edge http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solar_edge/update").setLevel(storage.get_number("log_level") or 99)
	
	local function GetAsNumber(value)
		if type(value) == "number" then return value end
		local nv = tonumber(value,10)
		return (nv or 0)
	end

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
		watts = GetAsNumber(retData.currentPower.power)
		DayKWH = GetAsNumber(retData.lastDayData.energy)/1000
		if DayKWH ~= -1 then
			WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, dev.id)
		end	
		MonthKWH = GetAsNumber(retData.lastMonthData.energy)/1000
		YearKWH = GetAsNumber(retData.lastYearData.energy)/1000
		LifeKWH = GetAsNumber(retData.lifeTimeData.energy)/1000
		local timefmt = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
		local yyyy,mm,dd,h,m,s = retData.lastUpdateTime:match(timefmt)
		ts = os.time({day=dd,month=mm,year=yyyy,hour=h,min=m,sec=s})
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)