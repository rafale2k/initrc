#!/bin/bash
set -u

# --- 🏷️ Version Definition ---
INSTALL_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)
VERSION=$(<"$INSTALL_DIR/VERSION")

# パス確定
DOTPATH=$(cd "$(dirname "$0")" || exit 1; pwd)
export DOTPATH

# --- 🚀 Start Message ---
# 1. 共通関数の読み込み (モジュール分割後)
for f in "$DOTPATH/scripts/core/"*.sh "$DOTPATH/scripts/install/"*.sh "$DOTPATH/scripts/check/"*.sh; do
    if [ -f "$f" ]; then
        # shellcheck source=/dev/null
        source "$f"
    fi
done

log_info "🎯 Starting installation v${VERSION} from ${DOTPATH}..."

# 1. OS判定
detect_os_and_pm

# 2. SSH鍵の生成
log_info "🔐 Checking SSH keys..."
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
    log_success "SSH key generated."
else
    log_info "SSH key already exists."
fi

# 3. 実行シークエンス
setup_os_repos           # リポジトリ準備
install_all_packages     # パッケージ + git-extras インストール

log_info "🔗 Syncing submodules..."
# .git がなくても、中身が空っぽなら強制的に取得しに行く
if [ -d ".git" ] || [ -f "zsh/.zshrc" ]; then
     git config --global --add safe.directory "$DOTPATH"
     # .git がない場合は、ここで改めて clone するか init する
     git submodule update --init --recursive || log_warn "Submodule sync failed"
else
     log_warn "Context unknown, skipping..."
fi

setup_oh_my_zsh          # OMZ & プラグインリンク
setup_ai_tools           # AI ツール (ginv) 作成
deploy_configs "$HOME"   # 設定ファイル展開

# 4. Git Identity
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "rafale2k"
    git config --global user.email "rafale2k@example.com"
    log_success "Git Identity configured."
fi

# 5. Root対応 & PATH設定
setup_root_loader "$HOME"

log_info "⚙️  Verifying PATH in .zshrc..."
if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"; then
    # SC2016 対策: ダブルクォートを使って変数を適切にエスケープ
    sed -i "1i export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"
    log_success "PATH added to .zshrc."
fi

export PATH="$HOME/bin:$PATH"

# 6. Verification
if ! verify_installation; then
    log_warn "Some tools failed to verify. Please check the logs above."
fi

log_success "All processes completed successfully! (v${VERSION})"
log_info "🚀 Run 'exec zsh -l' to start your new environment."
