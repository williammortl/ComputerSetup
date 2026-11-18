#!/usr/bin/bash

sudo dnf update --refresh
sudo dnf install \
    git vim neovim curl wget make cmake fastfetch \
    sqlite3 nasm glpk-utils \
    gcc g++ clang \
    java-25-openjdk maven \
    dotnet-sdk-10.0 \
    go R octave ghc \
    python3-scipy \
    texlive-scheme-medium

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash

curl -fsSL https://antigravity.google/cli/install.sh | bash

curl -fsSL https://chatgpt.com/codex/install.sh | sh

sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

