-- Remove Enphase Remote device details
local function d_remove(device)
	local storage = require("storage")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_remote/remove").setLevel(storage.get_number("log_level") or 99)

	logger.debug("device %1", device)

	-- Set device specific variables.
	local id = math.floor(device.id)
	storage.delete("WeeklyDaily"..id)
	storage.delete("MonthlyDaily"..id)
	storage.delete("YearlyMonthly"..id)
	storage.delete("SM_RC_"..id)
end

d_remove(...)