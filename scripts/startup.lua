--[[
	Universal Solar Meter plugin for Ezo Linux based hubs
	
	File	: startup.lua
	Version	: 0.2
	Author	: Rene Boer
--]]
local PLUGIN = "SolarMeter"
local storage = require("storage")
local core = require("core")
local timer = require("timer")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/startup").setLevel(storage.get_number("log_level") or 99)

-- Add item by using zwave module defaults as template.
local function add_item(device, default_type, default_value, enum)
	local base_item = require("HUB:zwave/scripts/model/items/default/"..default_type)
	base_item.device_id = device
	if default_value then base_item.value = default_value end
	if enum then base_item.enum = enum end
	local item,err = core.add_item(base_item)
	if item then
		logger.debug("Add %1 item to %2: %3", default_type, device, item)
	else	
		logger.debug("Add %1 item to %2 failed. Error : %3", default_type, device, err)
	end
	return item
end

-- Add a number in storage if not exists.
local function first_storage_number(name, value)
	if not storage.exists(name) then
		storage.set_number(name, value)
	end
end

-- First run of plugin, do set-ups needed
local function set_configuration(config)
	logger.debug("set_configuration.config=%1", config)
	if storage.get_string("PLUGIN") == nil then
		-- First run, create storage objects we needed. Currently these values are not shown in UI.
		storage.set_string("PLUGIN", PLUGIN)
	end
	-- Update config variables
	storage.set_string("version", config.version)
	storage.set_number("log_level", config.log_level)
	storage.set_bool("remove_inactive", config.remove_inactive)
	logger.setLevel(config.log_level or 99)
end

local function create_devices(devices)
	logger.debug("create_devices.devices=%1", devices)
	-- Find the devices for this gateway. Each gateway (= plugin of type gateway) has its own 
	local gateway = core.get_gateway()
	local self_id = gateway.id
	local found = false
	local gw_devices = core.get_devices() or {}
	logger.debug("Hub has %1 devices", #gw_devices)
	local gateway_devices = {}
	for _,d in ipairs(gw_devices) do
		if d.gateway_id == self_id then
			logger.debug("Device %1 id %2 table %3", d.name, d.id)
			gateway_devices[d.id] = d
		end
	end
	-- Loop over devices and see what we need to create, update, remove
	for _,d in ipairs(devices) do
		local id = math.floor(d.id)
		local gw_devId = storage.get_string("SM_D_"..id)
		if d.active then
			local device = {}
			-- Do we have an existing device?
			if gateway_devices[gw_devId] == nil then
				-- Create new device
				logger.notice("Creating new Solar Meter device for %1.", d.name)
				gw_devId, err = core.add_device{
					gateway_id = self_id,
					type = "meter.power",
					device_type_id = "SolarMeter." .. d.path,
					name = d.name,
					room_id = d.room or "",
					category = "power_meter",
					subcategory = "",
					battery_powered = false,
					persistent = false,
					serviceNotification = false,
					info = {manufacturer = "Rene Boer", model = "Solar Meter ".. d.name}
				}
				assert(gw_devId,"Failed to create "..d.name..", error "..(err or "unknown"))
				-- Build new device table
				device.id = id
				device.name = d.name
				device.path = d.path
				device.device_id = gw_devId
				device.watt_itemId = add_item(gw_devId, "electric_meter_watt")
				device.kwh_itemId = add_item(gw_devId, "electric_meter_kwh")
--				device.amper_itemId = add_item(gw_devId, "electric_meter_amper")
--				device.volt_itemId = add_item(gw_devId, "electric_meter_volt")
				first_storage_number("Watts"..id, 0)
				first_storage_number("DayKWH"..id, 0)
				first_storage_number("WeekKWH"..id, 0)
				first_storage_number("MonthKWH"..id, 0)
				first_storage_number("YearKWH"..id, 0)
				first_storage_number("LifeKWH"..id, 0)
				first_storage_number("LastRefresh"..id, os.time()-900)
				-- Run device specific add routine.
				local add = loadfile( "HUB:"..PLUGIN.."/scripts/drivers/"..d.path.."/add" )
				if add then add({device = device, config = d.config}) end
			else
				-- Get existing device table from storage
				logger.info("Device for %1 exists with deviceId %2.", d.name, gw_devId)
				device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(gw_devId)
			end
			-- Set updatable parameters.
			device.active = d.active
			device.config = d.config
			device.poll_interval = d.poll_interval
			
			-- Update mapping variables
			loadfile("HUB:"..PLUGIN.."/scripts/utils/set_mapping")().set(gw_devId, device)

			-- Device is ready to go.
			core.update_reachable_state(gw_devId, true)
			core.update_ready_state(gw_devId, true)
			
			-- Run device specific start routine if availble. Else just start polling.
			local start = loadfile( "HUB:"..PLUGIN.."/scripts/drivers/"..d.path.."/start" )
			if start then 
				start({device = device, config = d.config})
			else
				-- Start polling routine, keep some time between devices.
				if device.poll_interval then
					local t_id = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_timer_id")().get(id)
					logger.debug("Setting timer %1 to poll in %2 sec.", t_id, id * 10)
					timer.set_timeout_with_id(id * 10 * 1000, t_id, "HUB:"..PLUGIN.."/scripts/poll", {device_id =  device.device_id})
				else
					logger.err("No poll interval set for device %1, check SolarMeter.json configuration.", id)
				end
			end
		else
			-- See if we have an existing device and if it needs to be removed.
			local remove_inactive = storage.get_bool("remove_inactive") or false
			if remove_inactive then
				if gw_devId then 
					if gateway_devices[gw_devId] then
						logger.notice("Removing device %1 name %2, no longer active in SolarMeter.json configuration.", id, d.name)
						core.remove_device(gw_devId)
					end
				end	
			end
		end
	end

end

local function startup(...)
	local startup_args = {...}
	logger.debug("startup.startup_args=%1", startup_args)

	local json = require("HUB:"..PLUGIN.."/scripts/utils/dkjson")
	local config_file = "/home/data/custom_plugins/"..PLUGIN.."/SolarMeter.json"
	
	local platform = _G._PLATFORM or "linux"
	local hw_rev = _G._HARDWARE_REVISION or 1
	logger.debug("Platform=%1, Hardware Revision %2", platform, hw_rev)
	
	local gateway = core.get_gateway()
	if gateway == nil then
		logger.crit("Failed to get a gateway. Check config.json.")
		return false
	else
		logger.info("My gateway is %1",gateway.id)
	end	
	
	-- Read configuration file for Solar meter device(s) to create.
	local config
	local f = io.open(config_file, "r")
	if f then
		config = json.decode((f:read("*a")))
		f:close()
		if type(config) ~= "table" then
			logger.crit("Unable to decode configuration file %1.", config_file)
			return false
		end
		logger.info("Read configuration version %1.", config.config.version)
	else
		logger.crit("Unable to read configuration file %1.", config_file)
		return false
	end
	-- Do plugin configuration
	set_configuration(config.config)

	-- Subscribe to all events so we can handle them.
	core.subscribe("HUB:"..PLUGIN.."/scripts/events/handler")

	-- Add Solar Meter power devices
	create_devices(config.devices)
end

-- Actually run the startup function; pass all arguments, let the function sort it out.
startup(...)
