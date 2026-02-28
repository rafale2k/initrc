#!/bin/bash
# shellcheck disable=SC1091,SC2034

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

# --- git-extras: Git 拡張サブコマンド群のインストール ---
install_git_extras() {
    local PM=$1; local SUDO_CMD=$2
    echo "🛠️  Installing git-extras via $PM..."
    case "$PM" in
        "apt")
            $SUDO_CMD apt install -y git-extras
            ;;
        "dnf")
            # EPEL リポジトリが有効である前提 (setup_os で対応済み)
            $SUDO_CMD dnf install -y git-extras
            ;;
        "brew")
            brew install git-extras
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
        "brew")
            # Macは sudo 不要、-y も不要
            brew install bat
            ;;
        *)
            # RHEL/DNFなどは -y が必要。SUDO_CMDが空でも動くようにクォートなしで展開
            ${SUDO_CMD} ${PM} install -y bat
            ;;
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
        "brew")
            # Macは brew で直接 install (sudoと-yは不要)
            brew install fd
            ;;
        *)
            # RHEL/DNF など、それ以外の場合
            ${SUDO_CMD} ${PM} install -y fd
            ;;
    esac
}

# --- Docker & Docker Compose: 公式リポジトリからのインストール ---
install_docker() {
    local PM=$1; local SUDO_CMD=$2
    echo "🐳 Installing Docker Engine and Compose via $PM..."
    case "$PM" in
        "apt")
            # 依存パッケージとGPGキーの登録
            $SUDO_CMD apt update
            $SUDO_CMD apt install -y ca-certificates curl gnupg
            $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg

            # リポジトリの追加
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            $SUDO_CMD apt update
            $SUDO_CMD apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "dnf")
            # RHEL/CentOS系は公式リポジトリを追加
            $SUDO_CMD dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            $SUDO_CMD systemctl enable --now docker
            ;;
        "brew")
            # macOSは Docker Desktop または OrbStack を使うのが一般的やけど、CLIツールだけならこれ
            brew install docker docker-compose
            ;;
    esac
}

# --- xclip: Linux 用クリップボード連携ツールのインストール ---
install_xclip() {
    local PM=$1; local DOTPATH=$2; local SUDO_CMD=$3
    echo "📋 Installing xclip for clipboard support via $PM..."
    case "$PM" in
        "apt") $SUDO_CMD apt install -y xclip ;;
        "dnf") $SUDO_CMD dnf install -y xclip ;;
        "brew") echo "🍺 macOS already has pbcopy/pbpaste." ;;
    esac
}

# install_functions.sh の末尾に追記
install_monokai_palette() {
    local DOTPATH=$1
    echo "🎨 Setting up Monokai Terminal Palette..."
    # 実行権限を付与
    chmod +x "$DOTPATH/bin/monokai-palette.sh"
    # あとは ~/.zshrc の末尾に呼び出しを追記する処理などを書く
}
