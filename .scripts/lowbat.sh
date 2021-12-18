#!/bin/sh
acpi -b | grep "Battery 0" | awk -F'[,:%]' '{print $2, $3}' | {
	read -r status capacity
	if [ "$status" = Discharging -a "$capacity" -lt 2 ]; then
		logger -p crit "Critical battery threshold - poweroff!"
		#systemctl poweroff
	fi
	if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
		logger -p crit "Critical battery threshold - suspend now"
		#systemctl suspend
	fi
}
