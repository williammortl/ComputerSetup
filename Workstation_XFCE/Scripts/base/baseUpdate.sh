#!/usr/bin/bash

sudo dnf update --refresh
sudo flatpak update
cd ~/Code && ./update_all_git.sh

