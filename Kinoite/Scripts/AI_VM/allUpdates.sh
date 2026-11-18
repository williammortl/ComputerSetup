#!/usr/bin/bash

sudo dnf update --refresh
rustup update
agy update
codex update
npm update -g
cd ~/Code && ./update_all_git.sh

