#!/usr/bin/bash

sudo dnf update --refresh
sudo dnf install \
    vim neovim curl wget make cmake fastfetch \
    sqlite3 nasm glpk-utils \
    gcc g++ clang \
    java-25-openjdk maven \
    dotnet-sdk-10.0 \
    go R octave ghc \
    python3-scipy jupyter \
    texlive-scheme-medium texstudio

distrobox-export --app texstudio

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

sudo dnf install --refresh code

distrobox-export --app code


