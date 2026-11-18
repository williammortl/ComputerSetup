#!/usr/bash/bin

curl -fL -o chatgpt.x86_64.rpm \
  https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm

sudo dnf install ./chatgpt.x86_64.rpm

cat >> ~/.bashrc <<'EOF'

# Launch ChatGPT independently of the terminal
alias gpt='setsid -f chatgpt --ozone-platform=x11 --disable-gpu </dev/null >/dev/null 2>&1'
EOF

source ~/.bashrc
