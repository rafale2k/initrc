#!/bin/bash

# =================================================================
# Rafale's dotfiles - Universal Installer (Full Metal Edition)
# =================================================================

set -e

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 0. SSH 鍵のセットアップ & GitHub 接続テスト
# ---------------------------------------------------------
echo "🔑 Checking SSH configuration..."
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    echo "🆕 SSH key not found. Generating a new one..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"
    echo "✅ New SSH key generated."
    echo "📋 Your public key is:"
    cat "${SSH_KEY}.pub"
    echo "👉 Add this to GitHub: https://github.com/settings/keys"
    echo "Press Enter once added to continue..."
    read
fi

echo "🔍 Testing GitHub SSH connection..."
# StrictHostKeyChecking=accept-new で初回接続もスムーズに
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated" || echo "⚠️ SSH Auth failed, but continuing..."

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
# 3. モダンツールのインストール
# ---------------------------------------------------------
echo "🛠️  Installing required tools..."
# OSごとにパッケージ名が違うものを調整
if [ "$OS" = "debian" ]; then
    $SUDO_CMD $PM update -y
    TOOLS=("git" "curl" "zsh" "python3" "fzf" "bat")
elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD $PM install -y epel-release
    TOOLS=("git" "curl" "zsh" "python3" "fzf" "bat")
fi

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null && [ "$tool" != "bat" ]; then
        $SUDO_CMD $PM install -y "$tool"
    fi
done

# Ubuntuのbatcat対策
if [ "$OS" = "debian" ] && command -v batcat &> /dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
fi

# zoxide のインストール
if ! command -v zoxide &> /dev/null; then
    echo "🚀 Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ---------------------------------------------------------
# 4. サブモジュールの同期
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# ---------------------------------------------------------
# 5. シンボリックリンク作成 (フラット構成対応)
# ---------------------------------------------------------
echo "🖇️  Creating symbolic links..."

# .zshrc
ln -sf "$DOTPATH/.zshrc" "$HOME/.zshrc"

# .oh-my-zsh 本体のリンク
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"

# カスタムテーマ & プラグイン
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# .gitconfig
ln -sf "$DOTPATH/.gitconfig" "$HOME/.gitconfig"

# ---------------------------------------------------------
# 6. Git Identity 設定 (既存コードを継承)
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Git identity setup..."
    read -p "Enter Git User Name [Jane Doe]: " git_name
    git_name=${git_name:-"Jane Doe"}
    read -p "Enter Git User Email [example@email.com]: " git_email
    git_email=${git_email:-"example@email.com"}

    cat << EOF > "$GIT_LOCAL"
[user]
    name = $git_name
    email = $git_email
EOF
    echo "✅ Created $GIT_LOCAL"
fi

# ---------------------------------------------------------
# 7. 最終確定 & Zsh 切り替え
# ---------------------------------------------------------
echo "✨ Installation complete!"
[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

exec zsh -l
