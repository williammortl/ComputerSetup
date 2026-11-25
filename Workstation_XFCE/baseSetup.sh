#!/usr/bin/bash

sudo dnf install \
    chromium \
    lm_sensors \
    distrobox \
    fastfetch \
    git \
    vim \
    neovim \
    qemu-kvm \
    libvirt-daemon-config-network \
    libvirt-daemon-kvm \
    virt-install \
    virt-manager \
    virt-viewer

sudo flatpak install \
    org.gnome.Quadrapassel \
    org.gnome.Aisleriot \
    io.github.dosbox-staging \
    io.github.stella_emu.Stella \
    com.discordapp.Discord \
    org.libreoffice.LibreOffice \
    org.mozilla.thunderbird \
    org.gimp.GIMP \
    org.gnome.gedit \
    org.fedoraproject.MediaWriter \
    se.sjoerd.Graphs \
    io.dbeaver.DBeaverCommunity \
    io.podman_desktop.PodmanDesktop \
    org.gnome.Epiphany \
    org.kde.marknote \
    org.kde.drawy \
    org.gnome.Snapshot

# Disable OpenSSH server and socket activation
for unit in sshd.service sshd.socket; do
    if systemctl cat "$unit" &>/dev/null; then
        sudo systemctl disable --now "$unit"
    fi
done

echo "===== SSH SERVER ====="
systemctl is-enabled sshd.service sshd.socket 2>&1
systemctl is-active sshd.service sshd.socket 2>&1

echo
echo "===== XRDP SERVER ====="
systemctl is-enabled xrdp.service xrdp-sesman.service 2>&1

echo
echo "===== LISTENING SSH/RDP PORTS ====="
sudo ss -lntp '( sport = :22 or sport = :3389 )'

# flatpak access control
flatpak override --user --nofilesystem=/home/wmortl/Personal
flatpak override --user \
  --filesystem=/home/wmortl/VMs/DOS:rw \
  io.github.dosbox-staging
flatpak override --user --show

