-- SolarMeter pv_out http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/pv_out/update").setLevel(storage.get_number("log_level") or 99)

	local function GetAsNumber(value)
		if type(value) == "number" then return value end
		local nv = tonumber(value,10)
		return (nv or 0)
	end

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local d_t = {}
	string.gsub(data,"(.-),", function(c) d_t[#d_t+1] = c end)
	if #d_t > 3 then
		local id = math.floor(dev.id)
		watts = GetAsNumber(d_t[4])
		DayKWH = GetAsNumber(d_t[3])/1000
		if DayKWH ~= -1 then
			WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, id)
			MonthKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/month_total")().total(DayKWH, id)
			if MonthKWH ~= -1 then
				YearKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/year_total")().total(MonthKWH, id)
			end
		end
		local timefmt = "(%d%d%d%d)(%d%d)(%d%d) (%d+):(%d+)"
		local yyyy,mm,dd,h,m = string.match(d_t[1].." "..d_t[2],timefmt)
		ts = os.time({day=dd,month=mm,year=yyyy,hour=h,min=m,sec=0})
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data, expected a CSV string.", (data or "-missing-"))
		return nil
	end
end

return d_update(...)