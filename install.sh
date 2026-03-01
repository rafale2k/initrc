#!/bin/bash
set -e

# カレントディレクトリ取得
DOTPATH=$(cd "$(dirname "$0")" && pwd)

# 共通関数の読み込み
if [ -f "$DOTPATH/common/install_functions.sh" ]; then
    source "$DOTPATH/common/install_functions.sh"
else
    echo "❌ Error: common/install_functions.sh not found."
    exit 1
fi

echo "🎯 Starting installation from $DOTPATH..."

# 1. SSH鍵の生成・表示 (復活！)
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

# 環境変数をエクスポート（各関数で使用）
export PM OS SUDO_CMD DOTPATH

# 3. 実行シークエンス (この順序が正解)
setup_os_repos          # リポジトリ準備 (apt/dnf update 最小化)
install_all_packages    # パッケージ一括 (zsh含む)
setup_oh_my_zsh         # ~/.oh-my-zsh 本体の作成
echo "🔗 Syncing submodules..."
git submodule update --init --recursive
deploy_configs          # 全設定配備 & サブモジュールプラグインのリンク
setup_ai_tools          # llm & gemini

# 4. Git Identity 設定 (復活！)
if [ -z "$(git config --global user.name)" ]; then
    echo "👤 Setting up Git identity..."
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
fi

# 5. 最終仕上げ (Root対応)
setup_root_loader

echo "✨ All processes completed successfully!"
