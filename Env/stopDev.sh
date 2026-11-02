#!/usr/bin/bash

set -euo pipefail

CONTAINER_NAME="wmm_dev"

if [[ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" == "true" ]]; then
    podman stop "$CONTAINER_NAME"
else
    echo "Development container is already stopped."
fi

