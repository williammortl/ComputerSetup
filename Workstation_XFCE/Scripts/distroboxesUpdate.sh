#!/usr/bin/bash

distrobox enter Dev -- bash -lc "~/distroboxUpdate.sh"
distrobox enter Prod -- bash -lc "~/distroboxUpdate.sh"

