#!/bin/bash
set -u

# --- 🏷️ Version Definition ---
readonly VERSION="1.31.0"

# パス確定
DOTPATH=$(cd "$(dirname "$0")" && pwd)
export DOTPATH

# --- 🚀 Start Message ---
echo "🎯 Starting installation v${VERSION} from ${DOTPATH}..."

# 共通関数の読み込み
if [ -f "$DOTPATH/scripts/install_functions.sh" ]; then
    # shellcheck source=scripts/install_functions.sh
    source "$DOTPATH/scripts/install_functions.sh"
else
    echo "❌ Error: scripts/install_functions.sh not found."
    exit 1
fi

# 1. OS判定
OS="unknown"; PM="unknown"; SUDO_CMD="sudo"
if [ "$(uname)" == "Darwin" ]; then
    OS="mac"; PM="brew"; SUDO_CMD=""
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"
fi
echo "🌍 Detected OS: $OS (using $PM)"
export PM OS SUDO_CMD

# 2. SSH鍵の生成
echo "🔐 Checking SSH keys..."
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
fi

# 3. 実行シークエンス
setup_os_repos           # リポジトリ準備
install_all_packages     # パッケージ + git-extras インストール

echo "🔗 Syncing submodules..."
git config --global --add safe.directory "$DOTPATH"
git submodule update --init --recursive || { echo "❌ Git submodule sync failed"; exit 1; }

setup_oh_my_zsh          # OMZ & プラグインリンク
setup_ai_tools           # AI ツール (ginv) 作成
deploy_configs "$HOME"   # 設定ファイル展開

# 4. Git Identity
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
fi

# 5. Root対応 & PATH設定
setup_root_loader "$HOME"

echo "⚙️  Verifying PATH in .zshrc..."
if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"; then
    # SC2016 対策: ダブルクォートを使って変数を適切にエスケープ
    sed -i "1i export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"
fi

export PATH="$HOME/bin:$PATH"
echo "✨ All processes completed successfully! (v${VERSION})"
echo "🚀 Run 'exec zsh -l' to start your new environment."
