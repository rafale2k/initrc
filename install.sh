#!/bin/bash
# shellcheck disable=SC1091,SC2034

# =================================================================
# Rafale's dotfiles - Universal Installer (Full Integration)
# =================================================================

set -e

# --- 0. パスの取得 & 関数ライブラリのロード ---
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

if [ -f "$DOTPATH/common/install_functions.sh" ]; then
    source "$DOTPATH/common/install_functions.sh"
    echo "📚 Loaded common install functions."
else
    echo "❌ Error: common/install_functions.sh not found!"
    exit 1
fi

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 1. 権限 & SSH & OS判別
# ---------------------------------------------------------
echo "🔐 Adjusting permissions & Checking SSH..."

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
OS="unknown"; SUDO_CMD=""; PM=""
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"; PM="brew"
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"; [ "$EUID" -ne 0 ] && SUDO_CMD="sudo"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"; [ "$EUID" -ne 0 ] && SUDO_CMD="sudo"
fi
echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. ツールインストール (install_functions.sh の活用)
# ---------------------------------------------------------
# 環境変数の保存
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$HOME/.local/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"

echo "🛠️  Installing OS-specific base and toolset..."
# OSごとの初期セットアップ (EPEL等)
setup_os "$PM" "$SUDO_CMD"

# 関数経由でのインストール (OSごとの差異を吸収)
install_git_extras "$PM" "$SUDO_CMD"
install_eza "$PM" "$DOTPATH" "$SUDO_CMD"
install_bat "$PM" "$DOTPATH" "$SUDO_CMD"
install_fd "$PM" "$DOTPATH" "$SUDO_CMD"
install_docker "$PM" "$SUDO_CMD"
install_xclip "$PM" "$DOTPATH" "$SUDO_CMD"

# 標準パッケージで入る残りのツールを一括インストール
REMAINING_TOOLS=("tree" "git" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "jq" "wget" "pipx" "glow")
echo "📦 Installing standard packages: ${REMAINING_TOOLS[*]}"

if [ "$OS" = "debian" ]; then
    $SUDO_CMD "$PM" install -y "${REMAINING_TOOLS[@]}"
elif [ "$OS" = "mac" ]; then
    brew install "${REMAINING_TOOLS[@]}" || true
elif [ "$OS" = "rhel" ]; then
    $SUDO_CMD "$PM" install -y "${REMAINING_TOOLS[@]}"
fi

# ---------------------------------------------------------
# 3. AI ツール (llm) のセットアップ
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
# 4. サブモジュールの同期 & デプロイ
# ---------------------------------------------------------
echo "🔗 Syncing submodules..."
git submodule update --init --recursive || echo "⚠️  Submodule sync failed."

deploy_conf() {
    local src="$1"; local dst="$2"
    [ ! -e "$src" ] && { echo "❌ Source not found: $src"; return; }
    [ -L "$dst" ] || [ -e "$dst" ] && rm -rf "$dst"

    if [[ "$src" == *"nanorc" ]]; then
        sed "s|__DOTPATH__|$DOTPATH|g" "$src" > "$dst"
        echo "✅ Configured (sed): $dst"
    else
        ln -sf "$src" "$dst"
        echo "🔗 Linked: $dst -> $src"
    fi
}

echo "🖇️  Deploying configuration files..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"
deploy_conf "$DOTPATH/bash/.bashrc" "$HOME/.bashrc"
deploy_conf "$DOTPATH/configs/vimrc" "$HOME/.vimrc"
deploy_conf "$DOTPATH/configs/inputrc" "$HOME/.inputrc"
deploy_conf "$DOTPATH/configs/gitconfig" "$HOME/.gitconfig"
deploy_conf "$DOTPATH/configs/gitignore_global" "$HOME/.gitignore_global"
deploy_conf "$DOTPATH/configs/nanorc" "$HOME/.nanorc"
deploy_conf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"

# Oh My Zsh 関連のリンク
if [ -d "$DOTPATH/oh-my-zsh" ]; then
    [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ] && rm -rf "$HOME/.oh-my-zsh"
    ln -sfn "$DOTPATH/oh-my-zsh" "$HOME/.oh-my-zsh"
fi

mkdir -p "$HOME/.oh-my-zsh/custom/themes" "$HOME/.oh-my-zsh/custom/plugins"
[ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
[ -d "$DOTPATH/zsh/plugins/zsh-autosuggestions" ] && ln -sfn "$DOTPATH/zsh/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
[ -d "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" ] && ln -sfn "$DOTPATH/zsh/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# ---------------------------------------------------------
# 5. Git Identity 設定
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity..."
    if [ -t 0 ]; then
        read -r -p "Enter Git User Name: " git_user
        read -r -p "Enter Git Email: " git_email
    else
        git_user="Rafale-CI"; git_email="rafale2k@users.noreply.github.com"
    fi
    cat << EOF > "$GIT_LOCAL"
[user]
    name = ${git_user:-Rafale-CI}
    email = ${git_email:-rafale2k@users.noreply.github.com}
EOF
    chmod 600 "$GIT_LOCAL"
fi

# ---------------------------------------------------------
# 6. 特殊リンク & Monokai適用 & 完了
# ---------------------------------------------------------
echo "🚀 Finalizing..."
# zoxide 初期化
if ! grep -q "zoxide init zsh" "$DOTPATH/zsh/.zshrc"; then
    echo 'eval "$(zoxide init zsh)"' >> "$DOTPATH/zsh/.zshrc"
fi

# ★ ここが重要：Monokaiパレットを適用
if command -v install_monokai_palette &> /dev/null; then
    install_monokai_palette "$DOTPATH"
else
    # 直接スクリプトを叩くバックアップ
    [ -f "$DOTPATH/bin/monokai-palette.sh" ] && bash "$DOTPATH/bin/monokai-palette.sh"
fi

echo "✨ Installation complete! Rafale's environment is ready."

if [ "$EUID" -eq 0 ]; then
    echo "👤 Root mode: Run 'source ~/.bashrc'"
elif [ -n "$GITHUB_ACTIONS" ] || [ ! -t 0 ]; then
    echo "🤖 CI detected."
else
    command -v zsh &> /dev/null && exec zsh -l || echo "⚠️  Zsh not found."
fi
