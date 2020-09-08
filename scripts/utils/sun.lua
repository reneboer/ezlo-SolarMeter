-- Calculate sunrise and sunset values
local calc = {}

-- Due to single precision floating numbers on Ezlo FW this function is inaccurate.
local function sun(lat, lon, elev, t)
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
	local locale_offset = os.difftime(t, os.time(gmtnow))
	if gmtnow.isdst then locale_offset = locale_offset + 3600 end
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
	local function JE(j)
		return mflr((j - 2440587.5) * 86400) 
	end
	local w = w0(rlat,elev,decl)
	return { sunrise=JE(Jt-w/tau), sunset=JE(Jt+w/tau) }, 24*w/pi -- solar noon and day length
end

--- This calculation is pretty accurate for use on Elzo FW.
--- calculate sunrise (rise=true) or sunset (rise=false)
--- Source:
--- 	Almanac for Computers, 1990
--- 	published by Nautical Almanac Office
--- 	United States Naval Observatory
--- 	Washington, DC 20392
local function sun2(latitude, longitude, rise, zenith, tim)
	local mflr, msn, masn, mcs, macs, mpi, mtn, matn = math.floor, math.sin, math.asin, math.cos, math.acos, math.pi, math.tan, math.atan
	local pif, fpi = mpi/180, 180/mpi
	local localOffset = 1

	--- Get hours off GMT
	local gmtnow = os.date("!*t", tim) -- get GMT as table
	local nownow = os.date("*t", tim) -- get local as table
	local locale_offset = math.floor(os.difftime(tim, os.time(gmtnow))/3600)
	-- On HC2 the GMT is one hour too late is DST
	if nownow.isdst then localOffset = localOffset + 1 end

	-- 1. first get the day of the year
	local N = os.date("%j",tim)

	-- 2. convert the longitude to hour value and calculate an approximate time
	local lngHour = longitude / 15
	local  t
	if rise	then
		t = N + ((6 - lngHour) / 24)
	else
		t = N + ((18 - lngHour) / 24)
	end

	-- 3. calculate the Sun's mean anomaly
	local M = (0.9856 * t) - 3.289

	-- 4. calculate the Sun's true longitude
	local L = M + (1.916 * msn(pif * M)) + (0.020 * msn(pif * 2 * M)) + 282.634
	-- NOTE: L potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
	while L<0 do L=L+360 end
	while L>=360 do L=L-360 end

	-- 5a. calculate the Sun's right ascension
	local RA = fpi * matn(0.91764 * mtn(pif * L))
	-- NOTE: RA potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
	while RA<0 do RA=RA+360 end
	while RA>=360 do RA=RA-360 end

	-- 5b. right ascension value needs to be in the same quadrant as L
	local Lquadrant  = (mflr( L/90)) * 90
	local RAquadrant = (mflr(RA/90)) * 90
	RA = RA + (Lquadrant - RAquadrant)

	-- 5c. right ascension value needs to be converted into hours
	RA = RA / 15

	-- 6. calculate the Sun's declination
	local sinDec = 0.39782 * msn(pif * L)
	local cosDec = mcs(masn(sinDec))

	-- 7a. calculate the Sun's local hour angle
	local cosH = (mcs(pif*zenith) - (sinDec * msn(pif*latitude))) / (cosDec * mcs(pif*latitude))
	if (cosH >  1)	or (cosH < -1) then
		-- the sun never rises on this location (on the specified date)
		-- the sun never sets on this location (on the specified date)
		return 0
	end

	-- 7b. finish calculating H and convert into hours
	-- if if rising time is desired:
	local H
	if rise then
		H = 360 - fpi * macs(cosH)
	-- if setting time is desired:
	else
		H = fpi * macs(cosH)
	end
	H = H / 15

	-- 8. calculate local mean time of rising/setting
	local T = H + RA - (0.06571 * t) - 6.622

	-- 9. adjust back to UTC
	local UT = T - lngHour
	-- NOTE: UT potentially needs to be adjusted into the range [0,24) by adding/subtracting 24
	while UT<0 do UT=UT+24 end
	while UT>=24 do UT=UT-24 end

	-- 10. convert UT value to local time zone of latitude/longitude
	local localT = UT + localOffset
	
	-- 11 convert to epoch
	nownow.hour = mflr(localT)
	nownow.min = mflr((localT-nownow.hour)*60)
	nownow.sec = 0
	return os.time(nownow)
end

function calc.sunrise(lat, lon, zenith, t)
   	if t == nil then t = os.time() end -- t defaults to now
	-- zenith : 90.83 for civil
	if zenith == nil then zenith = 90.83333333333 end
	return sun2(lat, lon, false, zenith, t)
end

function calc.sunset(lat, lon, zenith, t)
   	if t == nil then t = os.time() end -- t defaults to now
	-- zenith : 90.83 for civil
	if zenith == nil then zenith = 90.83333333333 end
	return sun2(lat, lon, true, zenith, t)
end

function calc.isnight(lat, lon, elev, t)
   	if t == nil then t = os.time() end -- t defaults to now
	if elev == nil then elev = 90.83333333333 end
--	local res, dl = calc.sun(lat, lon, elev, t)
	local ss = sun2(lat, lon, false, elev, t)
	local sr = sun2(lat, lon, true, elev, t + 86400) -- Get tomorrows sunrise
	if ss == 0 or sr == 0 then	
		-- Sun does not set.
		return false, nil, nil
	else
		return (t > ss) and (t < (sr)), ss, sr
	end
end

return calc