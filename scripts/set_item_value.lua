--[[
	set_item_value.lua
	Handle "setter" events for items. 
--]]
local params = ...
local storage = require("storage")
local PLUGIN = storage.get_string("PLUGIN")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/set_item_value").setLevel(storage.get_number("log_level") or 99)

logger.debug("params=%1", params)
	
-- We do not expect to have a setter come in
logger.info("plugin does not have set_item_value need.")
