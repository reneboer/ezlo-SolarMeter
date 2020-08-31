# IP address of target eZLO system for test/dev
IP=192.168.178.109
# name of plugin
PID=SolarMeter

# Rule to make remote path, only needed once
mkdir: 
	ssh -i ~/.ssh/ezlo_edge root@$(IP) mkdir -p /home/data/custom_plugins/$(PID)

# Rule to test-compile firmware, used for simple syntax error detect so we don't send up obvious brokenness.
comp:
	luac -p scripts/*.lua
	luac -p scripts/utils/*.lua
	luac -p scripts/events/*.lua
	luac -p scripts/drivers/enphase_local/*.lua
	luac -p scripts/drivers/enphase_remote/*.lua
	luac -p scripts/drivers/pv_out/*.lua
	luac -p scripts/drivers/fronius/*.lua
	luac -p scripts/drivers/solar_edge/*.lua
	luac -p scripts/drivers/solarman/*.lua
	luac -p scripts/drivers/sungrow/*.lua

# Rule to copy the code to the LinuxEdge
copy: 
	scp -i ~/.ssh/ezlo_edge -r *.json scripts root@$(IP):/home/data/custom_plugins/$(PID)/

# Rule to stop the plugin
unreg: 
	ssh -i ~/.ssh/ezlo_edge root@$(IP) /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.unregister $(PID)
	
# Rule to restart the plugin
reg: 
	ssh -i ~/.ssh/ezlo_edge root@$(IP) /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.register $(PID)

# Rule to uninstall the plugin
uninstall: 
	ssh -i ~/.ssh/ezlo_edge root@$(IP) /opt/firmware/bin/ha-infocmd hub.extensions.custom_plugin.uninstall $(PID)

# Rule to send code up and restart the plugin
all: comp unreg copy reg
