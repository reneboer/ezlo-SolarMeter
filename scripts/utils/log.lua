--[[
	log.lua
	Test plugin/experimental code laboratory -- a hastily-built logging module to get better control
	than just using print() everywhere. Needs work, lots of it, but good enough for now.
	Patrick Rigney (rigpapa), patrick@toggledbits.com
--]]

local M = {}

M.LOGLEVEL = { [0]="crit", [1]="err", [2]="warn", [3]="notice", [4]="info", [5]="debug",
				crit=0, err=1, warn=2, notice=3, info=4, debug1=5 }

M.print = print

M.setPrefix = function ( pfx )
	M.prefix = pfx or ""
	return M
end

M.setLevel = function( n )
	M.level = n or 7
	return M
end

M.dump = function(t, seen)
	if type(t) == "string" then return string.format("%q", t )
	elseif type(t) ~= "table" then return tostring(t) end
	seen = seen or {}
	local sep = ""
	local str = "{ "
	for k,v in pairs(t) do
		local val
		if type(v) == "table" then
			if seen[v] then val = "(recursion)"
			else
				seen[v] = true
				val = M.dump(v, seen)
			end
		elseif type(v) == "string" then
			val = string.format("%q", v)
		elseif type(v) == "number" and (math.abs(v-os.time()) <= 86400) then
			val = tostring(v) .. "(" .. os.date("%x.%X", v) .. ")"
		else
			val = tostring(v)
		end
		str = str .. sep .. k .. "=" .. val
		sep = ", "
	end
	str = str .. " }"
	return str
end

M.log = function(level, msg, ...) -- luacheck: ignore 212
	local str
	local args = {...}
	if type(msg) == "table" then
		str = tostring(msg.prefix or M.prefix or "") .. ": " .. tostring(msg.msg or msg[1])
		level = msg.level or level
	else
		str = (M.prefix or "") .. ": " .. tostring(msg)
	end
	if level > (M.level or M.LOGLEVEL.notice) then return end
	str = string.gsub(str, "%%(%d+)", function( n )
			n = tonumber(n, 10)
			if n < 1 or n > #args then return "nil" end
			local val = args[n]
			if type(val) == "table" then
				return M.dump(val)
			elseif type(val) == "string" then
				return string.format("%q", val)
			elseif type(val) == "number" and math.abs(val-os.time()) <= 86400 then
				return tostring(val) .. "(" .. os.date("%x.%X", val) .. ")"
			end
			return tostring(val)
		end
	)
	M.print( string.format("%s %s %s", os.date("%Y-%m-%d.%X"), M.LOGLEVEL[level] or "?", str) )
end

M.crit = function(...) M.log( M.LOGLEVEL.crit, ... ) end
M.err = function(...) M.log( M.LOGLEVEL.err, ... ) end
M.warn = function(...) M.log( M.LOGLEVEL.warn, ... ) end
M.notice = function(...) M.log( M.LOGLEVEL.notice, ... ) end
M.info = function(...) M.log( M.LOGLEVEL.info, ... ) end
M.debug = function(...) M.log( M.LOGLEVEL.debug1, ... ) end

return M
