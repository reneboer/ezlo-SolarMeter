-- Calculate week (last 7-days) total for devices not reporting the value
local calc = {}

function calc.total(daily, id)
	if daily == -1 then return -1 end
	local storage = require("storage")
	local id = math.floor(id)
	-- See if we have a new daily value, if so recalculate
	local lastWeekDaily = storage.get_table("WeeklyDaily"..id)
	-- See if we have a new daily value, if so recalculate
	local numDays = tonumber(os.date("%w")) + 1
	if daily ~= lastWeekDaily[numDays] then
		local total = 0
		lastWeekDaily[numDays] = daily
		-- Add up seven days total
		for i = 1, 7 do
			total = total + lastWeekDaily[i]
		end
		storage.set_table("WeeklyDaily"..id, lastWeekDaily)
		return total
    else
		-- No change
		return -1
    end
end

return calc
