#!/bin/bash
set -e

# カレントディレクトリ取得
DOTPATH=$(cd "$(dirname "$0")" && pwd)

# 共通関数の読み込み
# shellcheck source=common/install_functions.sh
if [ -f "$DOTPATH/common/install_functions.sh" ]; then
    source "$DOTPATH/common/install_functions.sh"
else
    echo "❌ Error: common/install_functions.sh not found."
    exit 1
fi

echo "🎯 Starting installation from $DOTPATH..."

# 1. SSH鍵の生成・表示
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

# 環境変数をエクスポート（引数地獄の回避）
export PM OS SUDO_CMD DOTPATH

# 3. リポジトリ追加フェーズ
setup_os_repos

# 4. パッケージ一括インストールフェーズ
install_all_packages

# 5. AIツールのセットアップ
setup_ai_tools

# 6. サブモジュール & 設定配備
echo "🔗 Syncing submodules..."
git submodule update --init --recursive
deploy_configs

# 7. Git Identity (未設定時のみ)
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
fi

# 8. 最終仕上げ (Root対応)
setup_root_loader

echo "✨ All processes completed successfully!"
