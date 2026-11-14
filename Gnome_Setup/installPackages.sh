#!/usr/bin/env bash

set -euo pipefail

PACKAGE_FILE="packages.txt"

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "ERROR: packages.txt not found."
    exit 1
fi

mapfile -t PACKAGES < <(grep -vE '^[[:space:]]*(#|$)' "$PACKAGE_FILE")

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "No packages to install."
    exit 0
fi

echo "Installing ${#PACKAGES[@]} packages..."

sudo dnf install "${PACKAGES[@]}"

echo "Package installation complete."
