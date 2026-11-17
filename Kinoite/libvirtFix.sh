#!/usr/bin/bash

# Fix the running firewall configuration
sudo firewall-cmd --zone=libvirt --change-interface=virbr0

# Make the change persistent across reboots
sudo firewall-cmd --permanent --zone=libvirt --change-interface=virbr0

# Verify both configurations
sudo firewall-cmd --get-zone-of-interface=virbr0
sudo firewall-cmd --permanent --get-zone-of-interface=virbr0
