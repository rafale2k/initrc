#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# --- 🚀 INITRC_LOADER_GUARD ---
if [ -n "${INITRC_LOADER_LOADED:-}" ]; then
    return 0 2>/dev/null
    # exit は書かない（ShellCheck対策 兼 source時の安全策）
fi
export INITRC_LOADER_LOADED=1

# 1. パスの確定
export DOTFILES_PATH
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
elif [ -n "${ZSH_NAME:-}" ]; then
    DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
else
    DOTFILES_PATH="${HOME}/.dotfiles"
fi

# 2. ローカル環境変数を読み込む
if [ -f "$DOTFILES_PATH/configs/.env" ]; then
    source "$DOTFILES_PATH/configs/.env" > /dev/null 2>&1
fi

# 3. 共通スクリプトの自動読み込み
_ld_common_dir="$DOTFILES_PATH/common"
if [ -d "$_ld_common_dir" ]; then
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        if [ -r "$_ld_f" ]; then
            source "$_ld_f" > /dev/null 2>&1
        fi
    done
fi

# 4. シェル固有設定
if [ -n "${ZSH_VERSION:-}" ]; then
    _ld_zsh_dir="$DOTFILES_PATH/zsh"
    [ -r "$_ld_zsh_dir/hooks.zsh" ]   && source "$_ld_zsh_dir/hooks.zsh"   > /dev/null 2>&1
    [ -r "$_ld_zsh_dir/options.zsh" ] && source "$_ld_zsh_dir/options.zsh" > /dev/null 2>&1
    [ -r "$_ld_zsh_dir/aliases.zsh" ] && source "$_ld_zsh_dir/aliases.zsh" > /dev/null 2>&1
    [ -r "$_ld_zsh_dir/_p10k.zsh" ]   && source "$_ld_zsh_dir/_p10k.zsh"   > /dev/null 2>&1
    alias reload='exec zsh -l'
elif [ -n "${BASH_VERSION:-}" ]; then
    if [ "${EUID:-}" -eq 0 ]; then
        export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    fi
    alias reload='source ~/.bashrc'
fi

unset _ld_f _ld_common_dir _ld_zsh_dir
