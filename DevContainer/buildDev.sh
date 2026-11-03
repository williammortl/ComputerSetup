#!/usr/bin/bash

set -euo pipefail

CONTAINER_NAME="wmm_dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

podman build \
  --format docker \
  --pull=always \
  -t "$CONTAINER_NAME:latest" \
  "$SCRIPT_DIR"

podman images "localhost/$CONTAINER_NAME"

