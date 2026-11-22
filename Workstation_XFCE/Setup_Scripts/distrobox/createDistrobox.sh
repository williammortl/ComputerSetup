#!/usr/bin/bash

# Regression fix
#
# distrobox create \
#   --name development \
#   --image registry.fedoraproject.org/fedora:45 \
#   --home /home/wmortl/Dev \
#   --dry-run \
#   | sed 's/:ro:rslave/:ro,rslave/g' \
#   | tr '\n' ' ' \
#   | sh

mkdir -p /home/wmortl/Dev

distrobox create \
  --name development \
  --image registry.fedoraproject.org/fedora:45 \
  --home /home/wmortl/Dev

