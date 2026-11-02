FROM registry.fedoraproject.org/fedora:44

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN dnf -y upgrade --refresh && \
    dnf -y install --setopt=install_weak_deps=False \
        gcc \
        gcc-c++ \
        clang \
        clang-tools-extra \
        lld \
        lldb \
        llvm \
        make \
        cmake \
        ninja-build \
        meson \
        autoconf \
        automake \
        libtool \
        pkgconf-pkg-config \
        gdb \
        valgrind \
        golang \
        python3 \
        python3-pip \
        python3-devel \
        python3-virtualenv \
        python3-scipy \
        java-25-openjdk-devel \
        maven \
        dotnet-sdk-10.0 \
        ghc \
        cabal-install \
        openssl-devel \
        zlib-devel \
        libffi-devel \
        sqlite-devel \
        curl \
        wget \
        jq \
        tar \
        unzip \
        zip \
        which \
        findutils \
        procps-ng \
        less \
        vim-enhanced \
        sqlite \
        R \
        octave \
        nasm \
        glpk-utils \
        fastfetch \
        git \
        gh \
        && dnf clean all
        

# Create non-root development user
RUN useradd -m -u 1000 -s /bin/bash dev \
    && install -d -m 700 -o dev -g dev /home/dev/.ssh

USER dev
ENV HOME=/home/dev
WORKDIR /home/dev

# Toolchain locations
ENV NVM_DIR=/home/dev/.nvm
ENV CARGO_HOME=/home/dev/.cargo
ENV RUSTUP_HOME=/home/dev/.rustup
ENV PATH="/home/dev/.cargo/bin:/home/dev/.local/bin:${PATH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install NVM, Node.js LTS and TypeScript
RUN curl -fsSL \
    https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh \
    | PROFILE=/dev/null bash \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default 'lts/*' \
    && npm install -g typescript @openai/codex

# Initialize NVM in interactive shells
RUN printf '\nexport NVM_DIR="$HOME/.nvm"\n' >> ~/.bashrc \
    && printf '[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"\n' >> ~/.bashrc

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf \
    https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path \
    && rustup component add rustfmt clippy

# Install Google Antigravity CLI
RUN curl -fsSL \
    https://antigravity.google/cli/install.sh \
    | bash


# Configure Bash aliases and custom prompt
RUN cat >> /home/dev/.bashrc <<'EOF'

# Command aliases
alias clear='clear && fastfetch'
alias ls='ls --color=auto'
alias dir='ls -l'
alias dira='ls -la'

# Prompt colors
BLUE='\[\e[38;5;81m\]'
ORANGE='\[\e[38;5;202m\]'
WHITE='\[\e[97m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
RESET='\[\e[0m\]'

# Custom penguin prompt
PS1="⚙️ ${RESET}${BLUE}\u${RESET}${GREEN}@${RESET}${WHITE}\h ${ORANGE}\w ${GREEN}% ${WHITE}"
EOF

WORKDIR /Code

CMD ["/bin/bash"]

