-- Calculate best next poll interval for Enphase Remote device
local function d_interval(device, lastupdate, http_code)
	local storage = require("storage")
	local core = require("core")
	local PLUGIN = storage.get_string("PLUGIN")
	local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/drivers/enphase_remote/interval").setLevel(storage.get_number("log_level") or 99)

	logger.debug("device %1, last update %2.", device, lastupdate)

	if http_code == 409 then
		-- Polling limiter hit. Start again next day.
		logger.warn("Exceeded API rate limit. Increase polling interval.")
		return ((sunrise - os.time()) + 10)
	end
	
	-- Get sunset/sunrise is night for configured or hub location.
	local location = device.location
	if not location then location = core.get_location() end
	local isnight, sunset, sunrise = loadfile("HUB:"..PLUGIN.."/scripts/utils/sun")().isnight(location.latitude, location.longitude)
	local id = math.floor(device.id)
	local delta = os.time() - lastupdate
	local interval = device.poll_interval or 900
	local offset = device.poll_offset or 60
	local int = interval
	local item_watts = core.get_item(device.watt_itemId)
	local watts = item_watts.value.value or 0
--	local watts = storage.get_number("Watts"..id) or 0
	-- We do not poll at night time to avoid hitting API limit.
	-- Only stop when there really is no production (watts = 0) or no change in time-stamp for 3 * poll intervals.
	if isnight and (watts == 0 or (delta / interval) >= 3) then
		logger.info("Skipping polling at night")
		-- Enphase API does not return zero after panels stop reporting. So we need to force zero.
		if watts ~= 0 then
			storage.set_number("Watts"..id, 0)
			core.update_item_value(device.watt_itemId, {value = 0, scale = "watt"})
		end
		storage.set_number("SM_RC_"..id, 0)
		return ((sunrise - os.time()) + 10)
	else	
		local retry_count = storage.get_number("SM_RC_"..id) or 0
		if (delta/interval) >= 3 then 
			-- Last update was more then three intervals ago, happens when panels are not producing energy. If so try again after normal interval.
			int = interval
			if retry_count > 0 then storage.set_number("SM_RC_"..id, 0) end
		elseif delta > interval then
			-- See if an update got missed. Check in offset seconds. Need to be careful not to burn through max requests per day.
			retry_count = retry_count + 1
			int = offset * retry_count
			storage.set_number("SM_RC_"..id, retry_count)
		else
			-- Try again offset seconds past a sync up with remote interval.
			int = math.max(interval - (delta % interval), 0) + offset
			-- Normal so retry count to zero
			if retry_count > 0 then storage.set_number("SM_RC_"..id, 0) end
		end
	end
	logger.debug("Last data was %1 seconds ago. Interval is %2, offset %3, next poll in %4 seconds.", delta, interval, offset, int)
	return int
end

return d_interval(...)

