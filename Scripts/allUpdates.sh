#!/usr/bin/bash

sudo dnf upgrade --refresh
sudo flatpak update
rustup update
npm update -g
agy update
codex update
cd ~/Code && ./update_all_git.sh

