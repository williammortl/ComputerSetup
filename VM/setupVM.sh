#!/usr/bin/bash

sudo dnf update --refresh

lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS
# change name of device
sudo lvextend -l +100%FREE -r /dev/fedora_room10/root

sudo dnf install \
    git vim neovim curl wget make cmake fastfetch \
    sqlite3 nasm glpk-utils \
    gcc g++ clang \
    java-25-openjdk maven \
    dotnet-sdk-10.0 \
    go R octave ghc \
    python3-scipy \
    texlive-scheme-medium \
    xorg-x11-xauth

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash

curl -fsSL https://antigravity.google/cli/install.sh | bash

curl -fsSL https://chatgpt.com/codex/install.sh | sh

sudo mkdir -p /etc/ssh/sshd_config.d

echo 'X11Forwarding yes' | \
  sudo tee /etc/ssh/sshd_config.d/50-x11-forwarding.conf

sudo sshd -t && sudo systemctl reload sshd

# reboot then
sudo sshd -T | grep -i x11forwarding

sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

curl -fL -o chatgpt.x86_64.rpm \
  https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm

sudo dnf install ./chatgpt.x86_64.rpm

cat >> ~/.bashrc <<'EOF'

# Launch ChatGPT independently of the terminal
alias gpt='setsid -f chatgpt --ozone-platform=x11 --disable-gpu </dev/null >/dev/null 2>&1'
EOF

source ~/.bashrc

CON=$(nmcli -g GENERAL.CONNECTION device show enp1s0)

sudo nmcli connection modify "$CON" \
  ipv4.method manual \
  ipv4.addresses 192.168.122.101/24 \
  ipv4.gateway 192.168.122.1 \
  ipv4.dns 192.168.122.1 \
  connection.autoconnect yes

sudo nmcli connection up "$CON"


