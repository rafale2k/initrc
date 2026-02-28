#!/bin/bash
# shellcheck disable=SC1091,SC2034

# =================================================================
# Rafale's dotfiles - Universal Installer (v1.17.0)
# =================================================================

set -e

DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$DOTPATH"

echo "🎯 Starting installation from $DOTPATH..."

# ---------------------------------------------------------
# 0. 権限 & SSH & OS判別 (一括処理)
# ---------------------------------------------------------
[ -d "$(dirname "$DOTPATH")" ] && chmod o+x "$(dirname "$DOTPATH")" || true
chmod -R o+rX "$DOTPATH" || true

SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -q
    chmod 600 "$SSH_KEY"
fi

if [ "$(uname)" = "Darwin" ]; then
    OS="mac"; PM="brew"; SUDO_CMD=""
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
fi

# ---------------------------------------------------------
# 1. パス情報の保存 & ツールインストール
# ---------------------------------------------------------
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$HOME/.local/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"

if [ "$OS" = "debian" ]; then
    $SUDO_CMD $PM update -y
    REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd-find" "jq" "wget" "pipx" "glow")
    for tool in "${REQUIRED_TOOLS[@]}"; do
        t=$tool; [ "$tool" = "bat" ] && t="batcat"
        $SUDO_CMD $PM install -y "$t" || echo "⚠️  Failed to install $tool"
    done
fi

# ---------------------------------------------------------
# 2. デプロイ関数 (nanorc置換対応)
# ---------------------------------------------------------
deploy_conf() {
    local src="$1"
    local dst="$2"
    [ ! -e "$src" ] && { echo "❌ Source not found: $src"; return; }
    [ -L "$dst" ] || [ -e "$dst" ] && rm -rf "$dst"

    if [[ "$src" == *"nanorc" ]]; then
        sed "s|__DOTPATH__|$DOTPATH|g" "$src" > "$dst"
        echo "✅ Configured (dynamic path): $dst"
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

# ---------------------------------------------------------
# 3. Git Identity 設定 (リポジトリ外管理)
# ---------------------------------------------------------
GIT_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GIT_LOCAL" ]; then
    echo "👤 Setting up Git identity (Local only, not in repo)..."
    read -p "Enter Git User Name: " git_user
    read -p "Enter Git Email (noreply): " git_email
    cat << EOF > "$GIT_LOCAL"
[user]
    name = $git_user
    email = $git_email
EOF
    chmod 600 "$GIT_LOCAL"
    echo "✅ Created $GIT_LOCAL (Private)"
fi

# ---------------------------------------------------------
# 4. 特殊リンク & 完了
# ---------------------------------------------------------
[ -x "$(command -v batcat)" ] && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
[ -x "$(command -v fdfind)" ] && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

echo "✨ Installation complete!"
if [ "$EUID" -eq 0 ]; then
    echo "👤 Root mode: Run 'source ~/.bashrc'"
else
    command -v zsh &> /dev/null && exec zsh -l || echo "Run 'source ~/.bashrc'"
fi
