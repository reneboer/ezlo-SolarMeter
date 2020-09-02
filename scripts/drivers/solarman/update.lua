-- SolarMeter solarman http data response handler
local function d_update(device, data)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/solarman/update").setLevel(storage.get_number("log_level") or 99)
	
	local function GetAsNumber(value)
		if type(value) == "number" then return value end
		local nv = tonumber(value)
		return (nv or 0)
	end

	local ts, watts, DayKWH, WeekKWH, MonthKWH, YearKWH, LifeKWH = -1,-1,-1,-1,-1,-1,-1
	logger.debug("device %1, data %2", device, data)
	local retData = json.decode(data)
	if type(retData) == "table" then
	logger.debug("data %1",retData.result.deviceWapper.dataJSON)
		for key, value in pairs(retData.result.deviceWapper.dataJSON) do
			if key == "dt" then
				ts = math.floor(GetAsNumber(value) / 1000)
			elseif key == "1ab" then 		-- DC Output Total Power (Active)
				watts = GetAsNumber(value)
			elseif key == "1bd" then 		-- Daily Generation (Active)
				DayKWH = GetAsNumber(value)
				if DayKWH ~= -1 then
					WeekKWH = loadfile("HUB:"..PLUGIN.."/scripts/utils/week_total")().total(DayKWH, device.id)
				end	
			elseif key == "1be" then 	-- Monthly Generation (Active)
				MonthKWH = GetAsNumber(value)
			elseif key == "1bf" then 	-- Annual Generation (Active)
				YearKWH = GetAsNumber(value)
			elseif key == "1bc" then 	-- Total Generation (Active)
				LifeKWH = GetAsNumber(value)
			end	
		end
--		if watts == -1 then watts = 0 end	-- Not sure where to get it from, return zero rather than -1
		return {timestamp=ts, watts=watts, DayKWH=DayKWH, WeekKWH=WeekKWH, MonthKWH=MonthKWH, YearKWH=YearKWH, LifeKWH=LifeKWH}
	else
		logger.warn("Unexpected body data type %1, expected a JSON string.", type(retData))
		return nil
	end
end

return d_update(...)
