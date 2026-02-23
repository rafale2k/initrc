#!/bin/bash
# --- common/loader.sh ---

# 1. パスの確定
export DOTFILES_PATH="$HOME/dotfiles"
COMMON_DIR="$DOTFILES_PATH/common"

# 2. 共通スクリプト (_n や _git) の読み込み
if [ -d "$COMMON_DIR" ]; then
    for f in "$COMMON_DIR"/_*.sh; do
        [ -r "$f" ] && source "$f"
    done
fi

# 3. 各シェル固有設定の読み込み
if [ -n "$ZSH_VERSION" ]; then
    # --- Zsh の場合 ---
    ZSH_DIR="$DOTFILES_PATH/zsh"
    # 読み込み順序を固定して、確実にパレットとプロンプトを適用
    [ -r "$ZSH_DIR/hooks.zsh" ]   && source "$ZSH_DIR/hooks.zsh"
    [ -r "$ZSH_DIR/options.zsh" ] && source "$ZSH_DIR/options.zsh"
    [ -r "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh"
    [ -r "$ZSH_DIR/_p10k.zsh" ]   && source "$ZSH_DIR/_p10k.zsh"

elif [ -n "$BASH_VERSION" ]; then
    # --- Bash の場合 ---
    BASH_DIR="$DOTFILES_PATH/bash"
    # _omb.sh など、Bash固有の設定があればここで読み込む
    [ -f "$BASH_DIR/.bashrc" ] && source "$BASH_DIR/.bashrc"
fi

# 4. 変数のクリーンアップ
unset f ZSH_DIR BASH_DIR COMMON_DIR
