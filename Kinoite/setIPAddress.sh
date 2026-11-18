#!/usr/bin/bash

CON=$(nmcli -g GENERAL.CONNECTION device show enp1s0)

sudo nmcli connection modify "$CON" \
  ipv4.method manual \
  ipv4.addresses 192.168.122.101/24 \
  ipv4.gateway 192.168.122.1 \
  ipv4.dns 192.168.122.1 \
  connection.autoconnect yes

sudo nmcli connection up "$CON"
