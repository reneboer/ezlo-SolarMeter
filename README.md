# ezlo-SolarMeter
This is a Ezlo version of the equivalent Vera plugin. See https://github.com/reneboer/vera-SolarMeter for details.

This is one of the first Ezlo plugins out here and can give some pointers for other plugin developers on Ezlo in the future.

The plugin will only show as a power meter with the Watts and daily KWh values. Other values are collected and stored, but cannot (yet) be displayed.

### Changes for V2.0:
* Added items for KWH Weekly, Monthly, Yearly and Lifetime. You can see these via the API Tool.
* Added scene triggers for the new items. See file scene_blocks.json for how that is done.
* Added dynamic polling for Enphase Remote API. This will calculate the best time to poll so it is close to the portal having an updated value, and stops polling at night. This can also be done for other system where the portal API includes a last update timestamp. 
* Some overal code enhancements.

### Installation.
To install first create a folder SolarMeter in the /home/data/custom_plugins folder. Make sure SolarMeter is spelled exact with the same letter casing (upper S, upper M).
Next put all files in that folder, except this README and LICENSE. You must use the same folder structure. I.e. scripts, scripts/drivers, scripts/drivers/enphase_local, etc.

### Configuration
As there is no programmable UI (yet) for the Ezlo hubs the configuration is done in SolarMeter.json. It is the only file you need to edit.

* log_level: 1 critical and error messages only, 2 also warning messages, 3 also notice messages, 4 also info messages, 5 also debug messages
* remove_inactive: if set to true and you mark an existing device as no longer active, it will be removed with all its collected data.

The settings for your solar system are set in devices. An example for each supported is included. You can have up to 20 defined. The settings are self-explanatory  I think. Two things; make sure the id number is unique and between 1 and 20, do not change the path parameter as they is used to find the correct scripts for the solar system type. You can have multiple devices for the same type of solar meters. Just enter the different configuration under a different id.
Some settings that need some explanation:
* poll_dynamic; if true the plugin expects a script interval.lua in the driver folder. This script can be used to calculate the optimum interval for the next solar system API call. Currently implemented for Enhpase Remote API.

To calculate the optimum interval the script takes the timestamp from the last poll, and adds poll_interval + poll_offset. The poll_interval must match the update interval of the solar system API. The poll_offset is used to keep a little margin if needed.

To stop polling at night the location of the panels can be specified if different from the Ezlo Hub location, or if the latter is not correct. See the included SolarMeter.json for an example.

### Starting the plugin
The plugin is started with the following command (enter on hub)
> /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.register SolarMeter

### Stopping the plugin
The plugin is stopped with the following command (enter on hub)
> /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.unregister SolarMeter

### Uninstalling the plugin
When you want to uninstall the plugin you must first delete all created power meters in the App. Currently the uninstall command does not remove the devices a plugin created, and after you uninstalled the plugin you cannot delete a device. This is a known bug that should be fixed.
After deleting the devices with the following command (enter on hub)
> /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.uninstall SolarMeter

Next remove the plugin files else the plugin will reactivate at a reboot. You can also rename the config.json so starting the plugin will fail.

### The Makefile
If you have a Linux system at hand (like a Pi) you can also first put the files on that. The included Makefile can be used for the steps above:
- First set the IP address of your Hub in the Makefile
- make mkdir, will create the correct target folder
- make all, will stop the plugin, copy all files, start the plugin. Useful for making code changes.
- make copy, will copy all files. A restart of the plugin is only needed if the startup.lua or SolarMeter.json are changed. All other scripts are event driven and loaded again as events occur.

## Some developer tips
Making this plugin I learned some of the basics of plugin development on Ezlo. First forget the Vera model. Right now there is only a basic config.json script and Lua code. No device, service, or UI definitions. Also, all is event driven, so no big blob of code in one file, but lots of small files to handle the event and not more. As the code is loaded for each event as it occurs it quickly becomes beneficial to create a set of utility functions as you can see in the utils folder. To keep data between script calls you have to use the storage module to store/retrieve the data you need between calls.

The folder name you put the plugin files in and the id and gateway name should all be identical.

You can add your own scene blocks to use in scenes in the apps. For this add a sceneBlocks line in config.json. This must point to the file having the sceneblocks definitions. See scene_blocks.json for an example. On the Ezlo Hub you can find more examples in /opt/firmware/plugins/scene_blocks/templates/scene_blocks.json for the default definitions.

### Must have code
There are some bits of code that every plugin would probably need. These are specified in the plugin config.json
1. startup script runs when plugin is registered and hub is rebooted.
2. teardown script that is run when the plugin is stopped/unregistered.
3. if your plugin creates devices you must include a script for forceRemoveDeviceCommand.

If you have things to add, please let me know by opening an issue.
