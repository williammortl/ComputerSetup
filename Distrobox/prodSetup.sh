#!/usr/bin/bash

sudo dnf update --refresh
sudo dnf install \
    vim neovim curl wget fastfetch \
    texlive-scheme-medium texstudio \
    vlc

distrobox-export --app texstudio

distrobox-export --app vlc

# don't forget zoom!

