#!/usr/bin/bash

# this script really is meant to be run, its just meant to give
#   examples on how to create the distrobox

# Regression fix
distrobox create \
  --name dev \
  --image registry.fedoraproject.org/fedora:45 \
  --home /var/home/wmortl/Boxes/dev \
  --dry-run \
  | sed 's/:ro:rslave/:ro,rslave/g' \
  | tr '\n' ' ' \
  | sh

distrobox create \
  --name deb \
  --image debian:stable \
  --home /var/home/wmortl/Boxes/deb \
  --dry-run \
  | sed 's/:ro:rslave/:ro,rslave/g' \
  | tr '\n' ' ' \
  | sh

# distrobox create \
#   --name Dev \
#   --image registry.fedoraproject.org/fedora:45 \
#   --home /var/home/wmortl/Dev

