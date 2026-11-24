#!/usr/bin/bash

distrobox enter dev -- bash -lc "~/distroboxUpdate.sh"
distrobox enter prod -- bash -lc "~/distroboxUpdate.sh"

