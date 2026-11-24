#!/usr/bin/bash

mkdir Personal
mkdir Code
mkdir VMs

sudo rpm-ostree install \
    chromium \
    lm_sensors \
    distrobox \
    fastfetch \
    git \
    isoimagewriter \
    kate \
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
    se.sjoerd.Graphs \
    io.dbeaver.DBeaverCommunity \
    io.podman_desktop.PodmanDesktop

# Disable OpenSSH server and socket activation
for unit in sshd.service sshd.socket; do
    if systemctl cat "$unit" &>/dev/null; then
        sudo systemctl disable --now "$unit"
    fi
done

# Disable xrdp, if installed
for unit in xrdp.service xrdp-sesman.service; do
    if systemctl cat "$unit" &>/dev/null; then
        sudo systemctl disable --now "$unit"
    fi
done

# Disable KDE Plasma's RDP server
for unit in app-org.kde.krdpserver.service plasma-krdp_server.service; do
    if systemctl --user cat "$unit" &>/dev/null; then
        systemctl --user disable --now "$unit"
    fi
done

echo "===== SSH SERVER ====="
systemctl is-enabled sshd.service sshd.socket 2>&1
systemctl is-active sshd.service sshd.socket 2>&1

echo
echo "===== KDE RDP SERVER ====="
systemctl --user is-enabled app-org.kde.krdpserver.service 2>&1
systemctl --user is-active app-org.kde.krdpserver.service 2>&1

echo
echo "===== XRDP SERVER ====="
systemctl is-enabled xrdp.service xrdp-sesman.service 2>&1

echo
echo "===== LISTENING SSH/RDP PORTS ====="
sudo ss -lntp '( sport = :22 or sport = :3389 )'

# flatpak access control
flatpak override --user --nofilesystem=/var/home/wmortl/Personal
flatpak override --user \
  --filesystem=/var/home/wmortl/VMs/DOS:rw \
  io.github.dosbox-staging
flatpak override --user --show



