-- SolarMeter enphase local http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_local/update").setLevel(storage.get_number("log_level") or 99)

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
		local id = math.floor(device.id)
		watts = retData.wattsNow or -1
		DayKWH = (retData.wattHoursToday or -1000)/1000
		WeekKWH = (retData.wattHoursSevenDays or -1000)/1000
		LifeKWH = (retData.wattHoursLifetime or -1000)/1000
		if DayKWH ~= -1 then
			MonthKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/month_total")().total(DayKWH, id)
			if MonthKWH ~= -1 then
				YearKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/year_total")().total(MonthKWH, id)
			end
		end
		-- Only update time stamp if watts or DayKWH are changed.
		if watts == storage.get_number("Watts"..id) and DayKWH == storage.get_number("DayKWH"..id) then
			ts = storage.get_number("LastRefresh"..id)
			if ts == 0 then ts = os.time() end  -- First readout.
		else
			ts = os.time()
		end
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)
