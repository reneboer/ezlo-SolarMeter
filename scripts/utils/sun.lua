-- Calculate sunrise and sunset values
local calc = {}

function calc.sun(lat, lon, elev, t)
	local mflr, msn, masn, mcs, macs, msq = math.floor, math.sin, math.asin, math.cos, math.acos, math.sqrt
	if t == nil then t = os.time() end -- t defaults to now
	if elev == nil then elev = 0.0 end -- elev defaults to 0
	local pi = math.pi
	local tau = pi * 2
	local rlat = lat * pi / 180.0
	local rlon = lon * pi / 180.0
	-- Apply TZ offset for JD in local TZ not UTC; truncate time and force noon.
	local gmtnow = os.date("!*t", t) -- get GMT as table
	local nownow = os.date("*t", t) -- get local as table
	gmtnow.isdst = nownow.isdst -- make sure dst agrees
	local locale_offset = os.difftime( t, os.time( gmtnow ) )
	local n = mflr((t + locale_offset) / 86400 + 0.5 + 2440587.5) - 2451545.0
	local N = n - rlon / tau
	local M = (6.24006 + 0.017202 * N) % tau
	local C = 0.0334196 * msn(M) + 0.000349066 * msn(2 * M) + 0.00000523599 * msn(3 * M)
	local lam = (M + C + pi + 1.796593) % tau
	local Jt = 2451545.0 + N + 0.0053 * msn(M) - 0.0069 * msn(2 * lam)
	local decl = masn(msn(lam) * msn(0.409105))
	function w0(rl, elvm, dang, wid)
		wid = wid or 0.0144862
		return macs((msn((-wid) + (-0.0362330 * msq(elvm) / 1.0472)) -
				msn(rl) * msn(dang)) / (mcs(rl) * mcs(dang)))
	end
	local function JE(j) return mflr((j - 2440587.5) * 86400) end
	return { sunrise=JE(Jt-w0(rlat,elev,decl)/tau), sunset=JE(Jt+w0(rlat,elev,decl)/tau) }, 24*w0(rlat,elev,decl)/pi -- day length
end

function calc.isnight(lat, lon, elev, t)
	local res, dl = calc.sun(lat, lon, elev, t)
	if dl ~= dl then	
		-- Is nan, so sun does not set.
		return false
	else
    	if t == nil then t = os.time() end -- t defaults to now
		return (t > res.sunset) and (t < (res.sunrise+86400))
	end
end

return calc