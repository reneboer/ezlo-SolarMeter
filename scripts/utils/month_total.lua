-- Calculate month total for devices not reporting the value
local calc = {}

function calc.total(daily, id)
	if daily == -1 then return -1 end
	local storage = require("storage")
	local id = math.floor(id)
	-- See if we have a new daily value, if so recalculate
	local thisMonthDaily = storage.get_table("MonthlyDaily"..id)
	local numDays = tonumber(os.date("%d"))
	if numDays ~= 1 then
		if daily ~= thisMonthDaily[numDays] then
			local total = 0
			thisMonthDaily[numDays] = daily
			for i = 1, numDays do
				total = total + thisMonthDaily[i]
			end
			storage.set_table("MonthlyDaily"..id, thisMonthDaily)
			return total
		else
			-- No change
			return -1
		end
	else
		-- Set first value in array
		if daily ~= tonumber(thisMonthDaily[1]) then
			thisMonthDaily[1] = daily
			storage.set_table("MonthlyDaily"..id, thisMonthDaily)
			return daily
		else
			-- No change
			return -1
		end
	end  
end

return calc
