#!/bin/bash
# --- common/loader.sh ---

# 1. パスの確定
COMMON_DIR="$DOTFILES_PATH/common"
export DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

# 【追記】ローカル専用設定があれば読み込む (.gitignore推奨)
if [ -f "$DOTFILES_PATH/common/.env.local" ]; then
    source "$DOTFILES_PATH/common/.env.local"
fi

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
#    [ -f "$BASH_DIR/.bashrc" ] && source "$BASH_DIR/.bashrc"
fi

# 4. 変数のクリーンアップ
unset f

# ループ変数だけを掃除（パス変数は残す！）
unset f

# 5. 環境判定とプロンプト・エイリアスの強制適用
if [ -n "$ZSH_VERSION" ]; then
    # --- Zsh (一般ユーザー) 用 ---
    alias reload='exec zsh -l'
    # プロンプトは既存のテーマがあるようなので、ここでは reload の定義を優先
elif [ -n "$BASH_VERSION" ]; then
    # --- Bash (root) 用 ---
    export PROMPT_COMMAND=""
    if [ "$EUID" -eq 0 ]; then
        # root 専用: 赤背景 ROOT
        export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    fi
    # Bash 全般で reload を有効化
    alias reload='source ~/.bashrc'
fi
