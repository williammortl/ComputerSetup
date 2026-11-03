#!/usr/bin/bash

sudo fwupdmgr refresh --force
fwupdmgr get-devices
fwupdmgr get-updates
sudo fwupdmgr update

