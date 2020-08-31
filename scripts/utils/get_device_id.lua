-- Get the mapped device id from storage
local func = {}
function func.get(id)
	local storage = require "storage"
	return storage.get_string("SM_D_"..math.floor(id))
end
return func