-- Solarmeter module full reset event. When is this called?
local params = ...
local storage = require("storage")
local core = require("core")
local PLUGIN = storage.get_string("PLUGIN")
local logger = require("HUB:"..PLUGIN.."/scripts/utils/log").setPrefix(PLUGIN.."/scripts/events/module_reset").setLevel(storage.get_number("log_level") or 99)

logger.info("Resetting module. Params %1", params)
if params.status == "finished" then
    -- clear all databases
    core.remove_gateway_devices(core.get_gateway().id)
    storage.delete_all()
end
