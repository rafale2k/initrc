#!/bin/bash
# shellcheck disable=SC1091,SC2034

# =================================================================
# Rafale's dotfiles - Universal Installer (v1.11.0 AI Edition)
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

# ツールリスト（pipx を追加して LLM ツールを管理できるようにする）
REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd-find" "jq" "wget" "pipx" "glow")
INSTALL_LIST=()

if [ "$OS" = "mac" ]; then
    # Mac (Homebrew) 向けマッピング
    for tool in "${REQUIRED_TOOLS[@]}"; do
        case "$tool" in
            "fd-find") INSTALL_LIST+=("fd") ;;
            "ccze")    echo "⏭️  Skipping ccze on Mac (not in default brew)" ;;
            *)         INSTALL_LIST+=("$tool") ;;
        esac
    done
    # Brewを非対話モードで実行
    NONINTERACTIVE=1 brew install "${INSTALL_LIST[@]}" || echo "⚠️  Some tools failed to install via brew."

elif [ "$OS" = "debian" ]; then
    $SUDO_CMD $PM update -y
    for tool in "${REQUIRED_TOOLS[@]}"; do
        case "$tool" in
            "bat") INSTALL_LIST+=("batcat") ;;
            *)     INSTALL_LIST+=("$tool") ;;
        esac
    done
    for tool in "${INSTALL_LIST[@]}"; do
        $SUDO_CMD $PM install -y "$tool" || echo "⚠️  Failed to install $tool"
    done

elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD $PM install -y epel-release
    $SUDO_CMD $PM makecache
    INSTALL_LIST=("${REQUIRED_TOOLS[@]}")
    for tool in "${INSTALL_LIST[@]}"; do
        $SUDO_CMD $PM install -y "$tool" || echo "⚠️  Failed to install $tool"
    done
fi

# ---------------------------------------------------------
# 4. AI ツール (llm) のセットアップ
# ---------------------------------------------------------
echo "🤖 Setting up AI tools (llm)..."
# pipx のパスを一時的に通して実行
export PATH="$HOME/.local/bin:$PATH"

if command -v pipx &> /dev/null; then
    # llm 本体
    if ! command -v llm &> /dev/null; then
        pipx install llm --force
        pipx ensurepath
    fi
    # Gemini プラグイン
    llm install llm-gemini || echo "⚠️  llm-gemini plugin installation failed."
else
    echo "⚠️  pipx not found. Skipping llm installation."
fi

# ---------------------------------------------------------
# 5. 特殊なエイリアス（シンボリックリンク）設定
# ---------------------------------------------------------
mkdir -p "$HOME/.local/bin"

# fd へのリンク作成
if command -v fdfind &> /dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
elif command -v fd &> /dev/null; then
    ln -sf "$(command -v fd)" "$HOME/.local/bin/fd"
fi

# bat へのリンク作成
if command -v batcat &> /dev/null; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
elif command -v bat &> /dev/null; then
    ln -sf "$(command -v bat)" "$HOME/.local/bin/bat"
fi

# ---------------------------------------------------------
# 6. サブモジュールの同期
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# ---------------------------------------------------------
# 7. シンボリックリンク作成
# ---------------------------------------------------------
echo "🖇️  Creating symbolic links..."

ZSHRC_FILE="$DOTPATH/zsh/.zshrc"
if ! grep -q "zoxide init zsh" "$ZSHRC_FILE"; then
    # shellcheck disable=SC2016
    echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC_FILE"
fi

ln -sf "$ZSHRC_FILE" "$HOME/.zshrc"

# Oh My Zsh フォルダの処理
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"

# カスタムディレクトリの整備
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
ln -sf "$DOTPATH/.gitconfig" "$HOME/.gitconfig"

# ---------------------------------------------------------
# 8. Git Identity 設定
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity (Automatic)..."
    cat << EOF > "$GIT_LOCAL"
[user]
    name = Jane Doe
    email = example@email.com
EOF
    echo "✅ Created $GIT_LOCAL"
fi

# ---------------------------------------------------------
# 9. 完了
# ---------------------------------------------------------
[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

if [ "$CI" = "true" ]; then
    echo "✨ Installation complete!"
    echo "✅ CI environment detected. Skipping shell transition."
    exit 0
fi

echo "✨ Installation complete! Transitioning to Zsh..."
exec zsh -l
