#!/usr/bin/bash

fastfetch
df -h
free -h
sensors
upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null
sudo nvme smart-log /dev/nvme0

