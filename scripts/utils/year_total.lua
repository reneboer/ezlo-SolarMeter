-- Calculate year total for devices not reporting the value
local calc = {}

function calc.total(monthly, id)
	if monthly == -1 then return -1 end
	local storage = require("storage")
	-- See if we have a new daily value, if so recalculate
	local thisYearMonthly = storage.get_table("YearlyMonthly"..id)
	local month = tonumber(os.date("%m"))
	if month ~= 1 then
		if monthly ~= thisYearMonthly[month] then
			local total = 0
			thisYearMonthly[month] = monthly
			for i = 1, month do
				total = total + thisYearMonthly[i]
			end
			storage.set_table("YearlyMonthly"..id, thisYearMonthly)
			return total
		else
			-- No change
			return -1
		end
	else
		-- Set first value in array
		if monthly ~= thisYearMonthly[1] then
			thisYearMonthly[1] = monthly
			storage.set_table("YearlyMonthly"..id, thisYearMonthly)
			return monthly
		else
			-- No change
			return -1
		end
	end  
end

return calc
