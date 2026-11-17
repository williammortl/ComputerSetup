#!/usr/bin/bash

sudo rpm-ostree install \
    chromium \
    distrobox \
    fastfetch \
    git \
    isoimagewriter \
    kate \
    libvirt-daemon-config-network \
    libvirt-daemon-kvm \
    lm_sensors \
    neovim \
    qemu-kvm \
    vim \
    virt-install \
    virt-manager \
    virt-viewer

sudo usermod -aG libvirt $USER

sudo flatpak install \
    org.gnome.Quadrapassel \
    org.gnome.Aisleriot \
    io.github.dosbox-staging \
    io.github.stella_emu.Stella \
    com.discordapp.Discord \
    org.libreoffice.LibreOffice \
    org.mozilla.thunderbird \
    org.octave.Octave \
    se.sjoerd.Graphs
