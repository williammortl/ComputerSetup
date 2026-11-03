#!/usr/bin/bash

set -e

echo "Current kind version:"
kind --version || true

LATEST=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
    | grep '"tag_name":' \
    | cut -d '"' -f 4)

echo "Latest kind version: $LATEST"

curl -Lo /tmp/kind \
    "https://kind.sigs.k8s.io/dl/${LATEST}/kind-linux-amd64"

chmod +x /tmp/kind
sudo mv /tmp/kind /usr/local/bin/kind

echo
echo "Installed:"
kind --version

