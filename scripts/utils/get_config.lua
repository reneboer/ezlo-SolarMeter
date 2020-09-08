-- Get the config from storage
local func = {}
function func.get(id)
	local storage = require "storage"
	return storage.get_table("SM_C_"..math.floor(id))
end
return func