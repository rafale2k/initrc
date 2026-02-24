#!/bin/bash

# =================================================================
# Rafale's dotfiles - Universal Installer (Zero-Enter Edition)
# =================================================================

set -e

DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 0. SSH 鍵のセットアップ (完全自動)
# ---------------------------------------------------------
echo "🔑 Checking SSH configuration..."
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    echo "🆕 Generating a new SSH key (Silent Mode)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # -q で静かに、-f でパス指定、-N "" でパスフレーズなしを完全自動化
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -q
    echo "✅ New SSH key generated."
    echo "📋 Your public key is:"
    cat "${SSH_KEY}.pub"
    echo "-------------------------------------------------------"
    echo "👉 PLEASE ADD THIS TO: https://github.com/settings/keys"
    echo "-------------------------------------------------------"
    # ここは「待たずに」次へ行く
fi

echo "🔍 GitHub SSH connection test (Non-blocking)..."
# 接続テストはするが、失敗しても止まらずに警告を出すだけにする
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated" && echo "✅ GitHub Auth Success" || echo "⚠️  GitHub Auth skip (Add key later)"

# ---------------------------------------------------------
# 1. OS判別 & パッケージマネージャー設定
# ---------------------------------------------------------
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"; PM="brew"; SUDO_CMD=""
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
else
    OS="unknown"; PM="none"; SUDO_CMD=""
fi

# ---------------------------------------------------------
# 3. Rafale 指定ツールのインストール
# ---------------------------------------------------------
echo "🛠️  Installing Rafale's toolset..."
REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget")

if [ "$OS" = "debian" ]; then
    $SUDO_CMD $PM update -y
    INSTALL_LIST=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        case "$tool" in
            "fd") INSTALL_LIST+=("fd-find") ;;
            "bat") INSTALL_LIST+=("batcat") ;;
            *) INSTALL_LIST+=("$tool") ;;
        esac
    done
elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD $PM install -y epel-release
    $SUDO_CMD $PM makecache
    INSTALL_LIST=("${REQUIRED_TOOLS[@]}")
fi

for tool in "${INSTALL_LIST[@]}"; do
    CHECK_NAME=$tool
    [[ "$tool" == "fd-find" ]] && CHECK_NAME="fdfind"
    [[ "$tool" == "batcat" ]] && CHECK_NAME="batcat"
    if ! command -v "$CHECK_NAME" &> /dev/null; then
        $SUDO_CMD $PM install -y "$tool" || true
    fi
done

# Ubuntu 用リンク作成
if [ "$OS" = "debian" ]; then
    mkdir -p "$HOME/.local/bin"
    [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
fi

echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# ---------------------------------------------------------
# 5. シンボリックリンク作成 (zsh/.zshrc)
# ---------------------------------------------------------
echo "🖇️  Creating symbolic links..."
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"

if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"

mkdir -p "$HOME/.oh-my-zsh/custom/themes"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
ln -sf "$DOTPATH/.gitconfig" "$HOME/.gitconfig"

# ---------------------------------------------------------
# 6. Git Identity 設定 (完全固定・Enter不要)
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity (Automatic)..."
    # read を排除して直接書き込む
    GIT_NAME="Rafale"
    GIT_EMAIL="rafale2k@users.noreply.github.com"

    cat << EOF > "$GIT_LOCAL"
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
    echo "✅ Created $GIT_LOCAL without prompt."
fi

# ---------------------------------------------------------
# 7. 最終確定 & Zsh 切り替え
# ---------------------------------------------------------
echo "✨ Installation complete! Transitioning to Zsh..."
[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

exec zsh -l
