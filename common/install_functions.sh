#!/bin/bash

# --- OSごとの初期セットアップ (リポジトリ更新、RHEL固有ツール等) ---
setup_os() {
    local PM=$1; local SUDO_CMD=$2
    echo "🏗️  Starting OS-specific setup for $PM..."
    case "$PM" in
        "apt")
            echo "🔄 Updating apt repository..."
            $SUDO_CMD apt update -y
            ;;
        "dnf")
            echo "📦 Setting up RHEL/DNF (EPEL & CRB)..."
            $SUDO_CMD dnf install -y epel-release
            $SUDO_CMD dnf config-manager --set-enabled crb || true
            echo "📦 Installing RHEL-specific base tools..."
            $SUDO_CMD dnf install -y procps-ng util-linux-user || true
            ;;
        "brew")
            echo "🍺 Homebrew environment ready."
            ;;
    esac
}

# --- eza: 公式リポジトリ追加またはバイナリ直接展開 ---
install_eza() {
    local PM=$1; local DOTPATH=$2; local SUDO_CMD=$3
    case "$PM" in
        "apt")
            $SUDO_CMD mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/gierens.list
            $SUDO_CMD apt update && $SUDO_CMD apt install -y eza
            ;;
        "dnf")
            curl -L https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz
            mv ./eza "$DOTPATH/bin/eza" && chmod +x "$DOTPATH/bin/eza"
            ;;
        "brew") brew install eza ;;
    esac
}

# --- bat: Debian系の 'batcat' 問題を解決 ---
install_bat() {
    local PM=$1; local DOTPATH=$2; local SUDO_CMD=$3
    case "$PM" in
        "apt")
            $SUDO_CMD apt install -y bat
            mkdir -p "$DOTPATH/bin"
            ln -sf /usr/bin/batcat "$DOTPATH/bin/bat"
            ;;
        *) $SUDO_CMD $PM install -y bat ;;
    esac
}

# --- fd: Debian系の 'fdfind' 問題を解決 ---
install_fd() {
    local PM=$1; local DOTPATH=$2; local SUDO_CMD=$3
    case "$PM" in
        "apt")
            $SUDO_CMD apt install -y fd-find
            mkdir -p "$DOTPATH/bin"
            ln -sf /usr/bin/fdfind "$DOTPATH/bin/fd"
            ;;
        *) $SUDO_CMD $PM install -y fd ;;
    esac
}
