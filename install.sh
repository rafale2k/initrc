#!/bin/bash

# =================================================================
# Rafale's dotfiles - Universal Installer (Hybrid & Flat Version)
# =================================================================

set -e

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 0. GitHub SSH 接続テスト
# ---------------------------------------------------------
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new >/dev/null 2>&1 || true

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
export PATH="\$DOTFILES_PATH/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"

# ---------------------------------------------------------
# 3. モダンツールのインストール
# ---------------------------------------------------------
echo "🛠️  Installing required tools..."
REQUIRED_TOOLS=("git" "curl" "zsh" "python3")

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "🎁 $tool is missing. Installing..."
        $SUDO_CMD $PM install -y "$tool" 2>/dev/null || echo "Failed to install $tool, skipping..."
    fi
done

# zoxide (zコマンド) の自動インストール
if ! command -v zoxide &> /dev/null; then
    echo "🚀 Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    export PATH="$PATH:$HOME/.local/bin"
fi

# ---------------------------------------------------------
# 4. サブモジュールの同期
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# ---------------------------------------------------------
# 5. シンボリックリンク作成 (フラット構成対応版)
# ---------------------------------------------------------
echo "🖇️  Creating symbolic links..."

# .zshrc
ln -sf "$DOTPATH/.zshrc" "$HOME/.zshrc"

# .oh-my-zsh 本体のリンク (実体があれば消して張り直す)
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"

# カスタムテーマのリンク (zsh/themes -> OMZ)
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

# カスタムプラグインのリンク (zsh/plugins -> OMZ)
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# .gitconfig
ln -sf "$DOTPATH/.gitconfig" "$HOME/.gitconfig"

# ---------------------------------------------------------
# 6. Git Identity 設定
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

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔄 Switching shell to zsh..."
    exec zsh -l
else
    exec zsh -l
fi
