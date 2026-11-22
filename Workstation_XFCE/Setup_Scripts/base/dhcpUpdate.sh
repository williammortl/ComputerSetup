#!/usr/bin/bash

# Remove existing DHCP range
sudo virsh -c qemu:///system net-update default delete ip-dhcp-range \
  '<range start="192.168.122.2" end="192.168.122.254"/>' \
  --live --config

# Add the smaller DHCP range
sudo virsh -c qemu:///system net-update default add ip-dhcp-range \
  '<range start="192.168.122.2" end="192.168.122.99"/>' \
  --live --config

# Verify
sudo virsh -c qemu:///system net-dumpxml default
