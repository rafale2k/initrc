#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# --- 🚀 INITRC_LOADER_GUARD ---
# 二重読み込み防止
if [ -n "${INITRC_LOADER_LOADED:-}" ]; then
    return 0 2>/dev/null
fi
export INITRC_LOADER_LOADED=1

# 1. パスの確定 (超重要)
# パス計算をシンプルに固定する
export DOTFILES_PATH="/home/rafale/dotfiles"
_ld_common_dir="$DOTFILES_PATH/common"

# デバッグ用：何が起きているか画面に出す
echo "📂 DOTFILES_PATH is: $DOTFILES_PATH"

# ループで読み込み
if [ -d "$_ld_common_dir" ]; then
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        if [ -r "$_ld_f" ]; then
            echo "📖 Loading: $_ld_f"
            source "$_ld_f"
        fi
    done
fi

# 3. 各種設定の読み込み
# configs/.env があれば読み込む
if [ -f "$DOTFILES_PATH/configs/.env" ]; then
    source "$DOTFILES_PATH/configs/.env" > /dev/null 2>&1
fi

# 4. 共通設定 (_*.sh) のループ読み込み
_ld_common_dir="$DOTFILES_PATH/common"
if [ -d "$_ld_common_dir" ]; then
    # 確実に common/_system.sh 等を source する
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        if [ -r "$_ld_f" ]; then
            echo "📖 Loading: $_ld_f"  # 👈 これを追加
            source "$_ld_f"
        fi
    done
fi

# 5. Zsh 特有の設定読み込み
if [ -n "${ZSH_VERSION:-}" ]; then
    _ld_zsh_dir="$DOTFILES_PATH/zsh"
    # 以下のファイルがあれば順次読み込む
    [ -r "$_ld_zsh_dir/hooks.zsh" ]   && source "$_ld_zsh_dir/hooks.zsh"
    [ -r "$_ld_zsh_dir/options.zsh" ] && source "$_ld_zsh_dir/options.zsh"
    [ -r "$_ld_zsh_dir/aliases.zsh" ] && source "$_ld_zsh_dir/aliases.zsh"
    [ -r "$_ld_zsh_dir/_p10k.zsh" ]   && source "$_ld_zsh_dir/_p10k.zsh"
    
    # エイリアス上書き防止のため最後に定義
    alias reload='exec zsh -l'
elif [ -n "${BASH_VERSION:-}" ]; then
    [ "${EUID:-}" -eq 0 ] && export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    alias reload='source ~/.bashrc'
fi

# 後片付け
unset _ld_f _ld_common_dir _ld_zsh_dir _ld_current_script _ld_script_dir
