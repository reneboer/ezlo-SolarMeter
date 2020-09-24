--[[
	Universal Solar Meter plugin for Ezo Linux based hubs
	
	File	: startup.lua
	Version	: 2.3
	Author	: Rene Boer
--]]
local PLUGIN = "SolarMeter"
local storage = require("storage")
local core = require("core")
local timer = require("timer")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/startup").setLevel(storage.get_number("log_level") or 99)

-- Should match firmware\plugins\zwave\scripts\model\items\default as much as possible.
local ItemDetails = {
	electric_meter_watt = { 
		name = "electric_meter_watt",
		value_type = "power", 
		value = {value = 0, scale = "watt"}, 
		has_getter = true,
		has_setter = false
	}, 
	electric_meter_kwh = { 
		name = "electric_meter_kwh",
		value_type = "amount_of_useful_energy", 
		value = {value = 0, scale = "kilo_watt_hour"}, 
		has_getter = true, 
		has_setter = false
	},
	electric_meter_amper = {
		name = "electric_meter_amper",
		value_type = "electric_current", 
		value = {value = 0, scale = "ampere"}, 
		has_getter = true, 
		has_setter = false
	},
	electric_meter_volt = { 
		name = "electric_meter_volt",
		value_type = "electric_potential", 
		value = {value = 0, scale = "volt"}, 
		has_getter = true, 
		has_setter = false
	}
}

-- Add item to device.
local function add_item(device, item_name)
	local base_item = ItemDetails[item_name]
	base_item.device_id = device
	local item,err = core.add_item(base_item)
	if item then
		logger.debug("Add %1 item to %2: %3", item_name, device, item)
	else	
		logger.debug("Add %1 item to %2 failed. Error : %3", item_name, device, err)
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
	logger.setLevel(config.log_level or 99)
	logger.debug("set_configuration.config=%1", config)
	if storage.get_string("PLUGIN") == nil then
		-- First run, create storage objects we needed. Currently these values are not shown in UI.
		storage.set_string("PLUGIN", PLUGIN)
	end
	-- Update config variables
	storage.set_string("version", config.version)
	storage.set_number("log_level", config.log_level)
	storage.set_bool("remove_inactive", config.remove_inactive)
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
			logger.debug("Found existing device %1 id %2", d.name, d.id)
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
				-- Run device specific add routine.
				local add = loadfile( "HUB:"..PLUGIN.."/scripts/drivers/"..d.path.."/add" )
				if add then add({device = device, config = d.config}) end
			else
				-- Get existing device table from storage
				logger.info("Device for %1 exists with deviceId %2.", d.name, gw_devId)
				device = loadfile("HUB:"..PLUGIN.."/scripts/utils/get_device")().get(gw_devId)
			end
			-- Set update-able parameters.
			device.active = d.active
			device.poll_interval = d.poll_interval
			device.poll_dynamic = d.poll_dynamic
			device.poll_offset = d.poll_offset
			
			-- See if we need to add additional items we did not have in v1.0
			if not device.kwh_week_itemId then
				local base_item = ItemDetails["electric_meter_kwh"]
				base_item.device_id = gw_devId
				base_item.name = "electric_meter_kwh_week"
				local item, err = core.add_item(base_item)
				if item then
					device.kwh_week_itemId = item
				else
					logger.err("failed to add kwh_week item")
				end
				if not device.kwh_month_itemId then
					base_item.name = "electric_meter_kwh_month"
					local item, err = core.add_item(base_item)
					if item then
						device.kwh_month_itemId = item
					else
						logger.err("failed to add kwh_month item")
					end
				end	
				if not device.kwh_year_itemId then
					base_item.name = "electric_meter_kwh_year"
					local item, err = core.add_item(base_item)
					if item then
						device.kwh_year_itemId = item
					else
						logger.err("failed to add kwh_year item")
					end
				end	
				if not device.kwh_life_itemId then
					base_item.name = "electric_meter_kwh_life"
					local item, err = core.add_item(base_item)
					if item then
						device.kwh_life_itemId = item
					else
						logger.err("failed to add kwh_life item")
					end
				end	
			end
			-- See if we need to add additional items we did not have in v2.0
			if not device.kwh_reading_itemId then
				local item, err = core.add_item({
					device_id = gw_devId,
					name = "kwh_reading_timestamp",
					value_type = "int",
					value = os.time()-900,
					has_getter = true,
					has_setter = false })
				if item then
					device.kwh_reading_itemId = item
				else
					logger.err("failed to add last_refresh item")
				end
			end	
			
			-- Update mapping variables
			loadfile("HUB:"..PLUGIN.."/scripts/utils/set_mapping")().set(gw_devId, device, d.config)

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
						local rem = loadfile( "HUB:"..PLUGIN.."/scripts/delete_device" )
						if rem then
							rem(gw_devId)
						else
							logger.err("Cannot load delete_device script. Device %1 not removed.", gw_devId)
						end
						--core.remove_device(gw_devId)
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

	-- Subscribe to just the events can handle.
	-- Later add filter for just our devices
	-- Removed the need to listen for core events by changing the device_deleted script.
	-- core.subscribe("HUB:"..PLUGIN.."/scripts/events/handler", {exclude=false,rules={{event="device_removed"},{event="module_reset"}}})

	-- Add Solar Meter power devices
	create_devices(config.devices)
	
	-- some clean up options. used as needed.
end

-- Actually run the startup function; pass all arguments, let the function sort it out.
startup(...)
