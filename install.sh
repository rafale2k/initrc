#!/bin/bash
set -e

# カレントディレクトリ取得
DOTPATH=$(cd "$(dirname "$0")" && pwd)

# 共通関数の読み込み
if [ -f "$DOTPATH/common/install_functions.sh" ]; then
    # shellcheck source=common/install_functions.sh
    source "$DOTPATH/common/install_functions.sh"
else
    echo "❌ Error: common/install_functions.sh not found."
    exit 1
fi

echo "🎯 Starting installation v1.15.0 from $DOTPATH..."

# 1. SSH鍵の生成
echo "🔐 Checking SSH keys..."
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
fi
echo "📋 Public key: $(cat "$HOME/.ssh/id_ed25519.pub")"

# 2. OS判定
OS="unknown"; PM="unknown"; SUDO_CMD="sudo"
if [ "$(uname)" == "Darwin" ]; then
    OS="mac"; PM="brew"; SUDO_CMD=""
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"
fi
echo "🌍 Detected OS: $OS (using $PM)"

export PM OS SUDO_CMD DOTPATH

# 3. 実行シークエンス (この順序が 2026年最新の正解)
setup_os_repos          # リポジトリ準備
install_all_packages    # パッケージ一括インストール
setup_oh_my_zsh         # Oh My Zsh 本体の作成
echo "🔗 Syncing submodules..."
git submodule update --init --recursive

# 先に AI ツール (ginv) を物理的に作成
setup_ai_tools          

# 最後にリンクを貼る (これで ~/bin/ginv が確実にデプロイされる)
deploy_configs          

# 4. Git Identity 設定
if [ -z "$(git config --global user.name)" ]; then
    echo "👤 Setting up Git identity..."
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
fi

# 5. Root対応
setup_root_loader

# --- ここから追加：パスの強制確認と設定 ---
echo "⚙️  Verifying PATH in .zshrc..."
# \$ を使うことで、ファイルにはリテラルの $HOME が書き込まれる
if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.zshrc"
fi

# 今の実行中のシェル環境にも強制的に反映
export PATH="$HOME/bin:$PATH"

echo "✨ All processes completed successfully!"
echo "🚀 Run 'source ~/.zshrc' or just type 'ginv' now!"
