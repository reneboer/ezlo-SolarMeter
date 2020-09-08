--Store the mapping vatialbes in storage
local func = {}
function func.set(device_id, device, config)
	local storage = require "storage"
	local id = math.floor(device.id)
	storage.set_string("SM_D_"..id, device_id)
	storage.set_table("SM_C_"..id, config)
	storage.set_table("SM_M_"..device_id, device)
end
return func