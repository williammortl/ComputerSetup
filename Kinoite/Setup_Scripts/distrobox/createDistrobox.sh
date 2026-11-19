#!/usr/bin/bash

# Regression fix
#
# distrobox create \
#   --name development \
#   --image registry.fedoraproject.org/fedora:45 \
#   --home /var/home/wmortl/Dev \
#   --dry-run \
#   | sed 's/:ro:rslave/:ro,rslave/g' \
#   | tr '\n' ' ' \
#   | sh

mkdir -p /var/home/wmortl/Dev

distrobox create \
  --name development \
  --image registry.fedoraproject.org/fedora:45 \
  --home /var/home/wmortl/Dev

