#!/bin/bash
# shellcheck disable=SC1091,SC2034

# =================================================================
# Rafale's dotfiles - Universal Installer (v1.20.0 Full Edition)
# =================================================================

set -e

# パスの取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 0. 権限 & SSH & OS判別
# ---------------------------------------------------------
echo "🔐 Adjusting permissions & Checking SSH..."

# SC2015 対策: 権限調整
PARENT_DIR=$(dirname "$DOTPATH")
if [ -d "$PARENT_DIR" ]; then
    chmod o+x "$PARENT_DIR" || true
fi
chmod -R o+rX "$DOTPATH" || true

# SSH鍵のセットアップ
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "🆕 Generating a new SSH key..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -q
    chmod 600 "$SSH_KEY"
    echo "✅ New SSH key generated."
    echo "📋 Your public key is:"
    cat "${SSH_KEY}.pub"
    echo "-------------------------------------------------------"
    echo "👉 PLEASE ADD THIS TO: https://github.com/settings/keys"
    echo "-------------------------------------------------------"
fi

# OS判別
OS="unknown"
SUDO_CMD=""
PM=""
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"
    PM="brew"
elif [ -f /etc/debian_version ]; then
    OS="debian"
    PM="apt"
    [ "$EUID" -ne 0 ] && SUDO_CMD="sudo"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
    PM="dnf"
    [ "$EUID" -ne 0 ] && SUDO_CMD="sudo"
fi
echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 1. パス情報の保存 & ツールインストール
# ---------------------------------------------------------
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$HOME/.local/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"

echo "🛠️  Installing Rafale's toolset..."
REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd-find" "jq" "wget" "pipx" "glow")

if [ "$OS" = "debian" ]; then
    $SUDO_CMD "$PM" update -y
    for tool in "${REQUIRED_TOOLS[@]}"; do
        t=$tool
        [ "$tool" = "bat" ] && t="batcat"
        $SUDO_CMD "$PM" install -y "$t" || echo "⚠️  Failed to install $tool"
    done
elif [ "$OS" = "mac" ]; then
    echo "🍎 Installing tools via Homebrew..."
    NONINTERACTIVE=1 brew install "${REQUIRED_TOOLS[@]}" || true
elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD "$PM" install -y epel-release
    $SUDO_CMD "$PM" makecache
    for tool in "${REQUIRED_TOOLS[@]}"; do
        $SUDO_CMD "$PM" install -y "$tool" || echo "⚠️  Failed to install $tool"
    done
fi

# ---------------------------------------------------------
# 2. AI ツール (llm) のセットアップ
# ---------------------------------------------------------
echo "🤖 Setting up AI tools (llm)..."
export PATH="$HOME/.local/bin:$PATH"
if command -v pipx &> /dev/null; then
    if ! command -v llm &> /dev/null; then
        if pipx install llm --force; then
            pipx ensurepath || true
        fi
    fi
    llm install llm-gemini || echo "⚠️  llm-gemini plugin installation failed."
fi

# ---------------------------------------------------------
# 3. サブモジュールの同期
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive || echo "⚠️  Submodule sync failed."

# ---------------------------------------------------------
# 4. デプロイ関数
# ---------------------------------------------------------
deploy_conf() {
    local src="$1"
    local dst="$2"
    [ ! -e "$src" ] && { echo "❌ Source not found: $src"; return; }
    
    if [ -L "$dst" ] || [ -e "$dst" ]; then
        rm -rf "$dst"
    fi

    if [[ "$src" == *"nanorc" ]]; then
        # GitHubにパスを漏らさないための動的置換
        sed "s|__DOTPATH__|$DOTPATH|g" "$src" > "$dst"
        echo "✅ Configured (sed): $dst"
    else
        ln -sf "$src" "$dst"
        echo "🔗 Linked: $dst -> $src"
    fi
}

echo "🖇️  Deploying configuration files..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

# 基本設定のデプロイ
deploy_conf "$DOTPATH/bash/.bashrc" "$HOME/.bashrc"
deploy_conf "$DOTPATH/configs/vimrc" "$HOME/.vimrc"
deploy_conf "$DOTPATH/configs/inputrc" "$HOME/.inputrc"
deploy_conf "$DOTPATH/configs/gitconfig" "$HOME/.gitconfig"
deploy_conf "$DOTPATH/configs/gitignore_global" "$HOME/.gitignore_global"
deploy_conf "$DOTPATH/configs/nanorc" "$HOME/.nanorc"
deploy_conf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"

# Oh My Zsh フォルダの処理
if [ -d "$DOTPATH/oh-my-zsh" ]; then
    if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
        rm -rf "$HOME/.oh-my-zsh"
    fi
    ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"
    echo "🔗 Linked: Oh My Zsh"
fi

# カスタムディレクトリの整備（Rafale's favorite plugins）
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
[ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
[ -d "$DOTPATH/zsh/plugins/zsh-autosuggestions" ] && ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
[ -d "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" ] && ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# ---------------------------------------------------------
# 5. Git Identity 設定 (CI/非対話対応)
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity..."
    if [ -t 0 ]; then
        read -r -p "Enter Git User Name: " git_user
        read -r -p "Enter Git Email (noreply): " git_email
    else
        echo "🤖 Non-interactive environment: Using default."
        git_user="Rafale-CI"
        git_email="rafale2k@users.noreply.github.com"
    fi

    cat << EOF > "$GIT_LOCAL"
[user]
    name = ${git_user:-Rafale-CI}
    email = ${git_email:-rafale2k@users.noreply.github.com}
EOF
    chmod 600 "$GIT_LOCAL"
    echo "✅ Created $GIT_LOCAL"
fi

# ---------------------------------------------------------
# 6. 特殊リンク & 完了
# ---------------------------------------------------------
echo "🚀 Finalizing..."
[ -x "$(command -v batcat)" ] && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
[ -x "$(command -v fdfind)" ] && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

# zoxide 初期化チェック (SC2016 対策)
if ! grep -q "zoxide init zsh" "$DOTPATH/zsh/.zshrc"; then
    # shellcheck disable=SC2016
    echo 'eval "$(zoxide init zsh)"' >> "$DOTPATH/zsh/.zshrc"
fi

echo "✨ Installation complete!"

if [ "$EUID" -eq 0 ]; then
    echo "👤 Root mode: Run 'source ~/.bashrc'"
elif [ -n "$GITHUB_ACTIONS" ] || [ ! -t 0 ]; then
    echo "🤖 CI detected. Setup finished."
else
    if command -v zsh &> /dev/null; then
        exec zsh -l
    else
        echo "⚠️  Zsh not found. Run 'source ~/.bashrc'"
    fi
fi
