#!/bin/bash

# =================================================================
# Rafale's dotfiles - Universal Installer (Final Automated Edition)
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
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -q
    echo "✅ New SSH key generated."
    echo "📋 Your public key is:"
    cat "${SSH_KEY}.pub"
    echo "-------------------------------------------------------"
    echo "👉 PLEASE ADD THIS TO: https://github.com/settings/keys"
    echo "-------------------------------------------------------"
fi

echo "🔍 GitHub SSH connection test (Non-blocking)..."
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

echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. パス情報の保存
# ---------------------------------------------------------
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$HOME/.local/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"

# ---------------------------------------------------------
# 3. Rafale 指定ツールのインストール
# ---------------------------------------------------------
echo "🛠️  Installing Rafale's toolset..."

# ツールリスト（OSによる名前の違いを吸収）
REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd-find" "jq" "wget")

if [ "$OS" = "debian" ]; then
    $SUDO_CMD $PM update -y
    INSTALL_LIST=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        case "$tool" in
            "bat") INSTALL_LIST+=("batcat") ;;
            *) INSTALL_LIST+=("$tool") ;;
        esac
    done
elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD $PM install -y epel-release
    $SUDO_CMD $PM makecache
    # RHEL系では fd-find はそのまま fd-find というパッケージ名でOK（中身は /usr/bin/fd）
    INSTALL_LIST=("${REQUIRED_TOOLS[@]}")
fi

for tool in "${INSTALL_LIST[@]}"; do
    # チェック用の名前（fd, fdfind, bat, batcat などを考慮）
    CHECK_NAME=$tool
    [[ "$tool" == "fd-find" ]] && CHECK_NAME="fdfind"
    [[ "$tool" == "batcat" ]] && CHECK_NAME="batcat"
    
    # 既にコマンドが存在するか、またはそのエイリアスがあるか確認
    if ! command -v "$CHECK_NAME" &> /dev/null && \
       ! command -v "${CHECK_NAME%-find}" &> /dev/null; then
        echo "🎁 Installing $tool..."
        $SUDO_CMD $PM install -y "$tool" || echo "⚠️  Failed to install $tool, skipping..."
    fi
done

# ---------------------------------------------------------
# 4. 特殊なエイリアス設定 (Ubuntu 向け)
# ---------------------------------------------------------
if [ "$OS" = "debian" ]; then
    mkdir -p "$HOME/.local/bin"
    # Ubuntu で fdfind しかない場合は fd にリンク
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    # Ubuntu で batcat しかない場合は bat にリンク
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
fi

# ---------------------------------------------------------
# 5. サブモジュールの同期
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# ---------------------------------------------------------
# 6. シンボリックリンク作成
# ---------------------------------------------------------
echo "🖇️  Creating symbolic links..."

# zoxide init の追記 (存在しない場合のみ)
ZSHRC_FILE="$DOTPATH/zsh/.zshrc"
if ! grep -q "zoxide init zsh" "$ZSHRC_FILE"; then
    echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC_FILE"
fi

ln -sf "$ZSHRC_FILE" "$HOME/.zshrc"

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
# 7. Git Identity 設定 (Jane Doe 仕様)
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity (Automatic)..."
    GIT_NAME="Jane Doe"
    GIT_EMAIL="example@email.com"

    cat << EOF > "$GIT_LOCAL"
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
    echo "✅ Created $GIT_LOCAL with identity: $GIT_NAME"
fi

# ---------------------------------------------------------
# 8. 完了
# ---------------------------------------------------------
echo "✨ Installation complete! Transitioning to Zsh..."
[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

exec zsh -l
