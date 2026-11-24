#!/usr/bin/bash

sudo dnf update --refresh
sudo dnf install \
    vim neovim curl wget fastfetch \
    texlive-scheme-medium texstudio

distrobox-export --app texstudio

# don't forget zoom!

