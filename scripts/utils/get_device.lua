-- Get the device from storage
local func = {}
function func.get(device_id)
	local storage = require "storage"
	return storage.get_table("SM_M_"..(device_id or ""))
end
return func