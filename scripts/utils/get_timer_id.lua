-- Calculate timer ID string to use.
local func = {}
function func.get(id)
	return "SM_T_"..(math.floor(id))
end
return func