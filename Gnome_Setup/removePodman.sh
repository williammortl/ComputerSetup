#!/usr/bin/bash

sudo dnf remove \
    podman \
    podman-docker \
    podman-compose \
    podman-plugins \
    podman-remote \
    conmon \
    catatonit \
    containers-common-extra \
    netavark \
    aardvark-dns

