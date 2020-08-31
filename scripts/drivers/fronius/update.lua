-- SolarMeter fronius http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/fronius/update").setLevel(storage.get_number("log_level") or 99)

	local function GetAsNumber(value)
		if type(value) == "number" then return value end
		local nv = tonumber(value,10)
		return (nv or 0)
	end

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
		retData = retData.Body.Data
		local id = math.floor(dev.id)
		if retData.PAC then -- is missing when no energy is produced
			watts = GetAsNumber(retData.PAC.Value)
		else
			watts = 0
		end	
		if retData.DAY_ENERGY then DayKWH = GetAsNumber(retData.DAY_ENERGY.Value) / 1000 end
		if retData.YEAR_ENERGY then YearKWH = GetAsNumber(retData.YEAR_ENERGY.Value) / 1000 end
		if retData.TOTAL_ENERGY then LifeKWH = GetAsNumber(retData.TOTAL_ENERGY.Value) / 1000 end
		if DayKWH ~= -1 then
			WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, id)
			MonthKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/month_total")().total(DayKWH, id)
		end	
		-- Only update time stamp if watts or DayKWH are changed.
		if watts == storage.get_number("Watts"..id) and DayKWH == storage.get_number("DayKWH"..id) then
			ts = storage.get_number("LastRefresh"..id)
			if ts == 0 then ts = os.time() end  -- First readout.
		end
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)
