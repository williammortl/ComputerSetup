#!/usr/bin/bash

sudo rpm-ostree update
sudo flatpak update
cd ~/Code && ./update_all_git.sh

