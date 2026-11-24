#!/usr/bin/bash

sudo dnf update --refresh
sudo dnf install \
    git vim neovim curl wget make cmake fastfetch \
    sqlite3 nasm glpk-utils \
    gcc g++ clang \
    java-25-openjdk maven \
    dotnet-sdk-10.0 \
    go R octave ghc \
    python3-scipy jupyter

sudo dnf install --refresh octave

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

sudo dnf install --refresh code

distrobox-export --app code

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash

