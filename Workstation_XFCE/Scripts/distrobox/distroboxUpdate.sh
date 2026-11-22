#!/usr/bin/bash

if [ -n "$CONTAINER_ID" ]; then
	sudo dnf update --refresh
	rustup update
	npm update -g
	cd ~/Code && ./update_all_git.sh
else
	echo This must be run from inside Distrobox.
fi

