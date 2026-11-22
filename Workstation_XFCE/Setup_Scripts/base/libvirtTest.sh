#!/usr/bin/bash

echo "===== LIBVIRT NETWORK ====="
sudo virsh -c qemu:///system net-list --all

echo
echo "===== RUNTIME FIREWALL ZONE ====="
sudo firewall-cmd --get-zone-of-interface=virbr0

echo
echo "===== PERMANENT FIREWALL ZONE ====="
sudo firewall-cmd --permanent --get-zone-of-interface=virbr0
