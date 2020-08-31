-- SolarMeter core event handler.
local params = ...
local storage = require("storage")
local PLUGIN = storage.get_string("PLUGIN")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/events/handler").setLevel(storage.get_number("log_level") or 99)

-- See if a handler is defined and call it.
local handler = loadfile("HUB:"..PLUGIN.."/scripts/events/" .. params.event)
if handler then
	handler(params)
else
	logger.debug("Unsupported event %1",params)
end
