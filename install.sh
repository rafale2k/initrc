#!/bin/bash
set -u

# --- 🏷️ Version Definition ---
readonly VERSION="1.21.0"

# パス確定
DOTPATH=$(cd "$(dirname "$0")" && pwd)
export DOTPATH

# --- 🚀 Start Message ---
echo "🎯 Starting installation v${VERSION} from ${DOTPATH}..."

# 共通関数の読み込み (v1.17.0: common から scripts へ移動)
if [ -f "$DOTPATH/scripts/install_functions.sh" ]; then
    # shellcheck source=scripts/install_functions.sh
    source "$DOTPATH/scripts/install_functions.sh"
else
    echo "❌ Error: scripts/install_functions.sh not found."
    exit 1
fi

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

# 3. 実行シークエンス
# A. まずはリポジトリとパッケージ（zsh等）を入れる
setup_os_repos           # リポジトリ準備
install_all_packages     # パッケージ一括インストール

# B. 【重要】OMZをセットアップする前にサブモジュールを同期
echo "🔗 Syncing submodules (Powerlevel10k, etc.)..."
git config --global --add safe.directory "$(pwd)"
git submodule update --init --recursive || { echo "❌ Git submodule sync failed"; exit 1; }

# C. ポストチェック（パッケージがちゃんと入ったか）
SCRIPTS_DIR="$DOTPATH/scripts"
if [ -f "$SCRIPTS_DIR/check_tools.sh" ]; then
    echo "🔍 Verifying installed tools..."
    # shellcheck disable=SC1091
    source "$SCRIPTS_DIR/check_tools.sh"
fi

# D. ツールが揃った状態で設定ファイルを展開
setup_oh_my_zsh          # Oh My Zsh 本体の作成
echo "🔗 Syncing submodules..."

# AI ツール (ginv) を物理的に作成
setup_ai_tools          

# 各種設定ファイルのデプロイ (v1.17.0: 内部で deploy_local_configs も呼ぶように統合済み)
deploy_configs "$HOME"         

# 4. Git Identity 設定 (v1.17.0: 既に .gitconfig.local があればそれを優先)
if [ -z "$(git config --global user.name)" ]; then
    echo "👤 Setting up Git identity..."
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
fi

# 5. Root対応
setup_root_loader "$HOME"

# --- パスの強制確認と設定 ---
echo "⚙️  Verifying PATH in .zshrc..."
if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.zshrc"
fi

export PATH="$HOME/bin:$PATH"

echo "✨ All processes completed successfully! (v${VERSION})"
echo "🚀 Run 'exec zsh -l' to start your new environment."
