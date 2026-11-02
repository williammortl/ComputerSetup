#!/usr/bin/bash

set -euo pipefail

CONTAINER_NAME="wmm_dev"

if [[ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" != "true" ]]; then
    echo "Development container is not running."
    echo "Run startDev.sh first."
    exit 1
fi

podman exec -it \
  --workdir /Code \
  "$CONTAINER_NAME" bash

