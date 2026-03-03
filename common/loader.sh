#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# --- 🚀 INITRC_LOADER_GUARD ---
if [ -z "$INITRC_LOADER_LOADED" ]; then
    export INITRC_LOADER_LOADED=1

    # 1. パスの確定 (SC2128対策: 配列としてアクセス)
    export DOTFILES_PATH
    if [ -n "${BASH_SOURCE[0]}" ]; then
        DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    elif [ -n "$ZSH_NAME" ]; then
        DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
    else
        DOTFILES_PATH="${HOME}/.dotfiles"
    fi

    # 2. ローカル環境変数を読み込む
    if [ -f "$DOTFILES_PATH/configs/.env" ]; then
        source "$DOTFILES_PATH/configs/.env" > /dev/null 2>&1
    fi

    # 3. 共通スクリプトの自動読み込み (localを使わずunsetで管理)
    _loader_common_dir="$DOTFILES_PATH/common"
    if [ -d "$_loader_common_dir" ]; then
        for _loader_f in "$_loader_common_dir"/_*.sh; do
            if [ -r "$_loader_f" ]; then
                source "$_loader_f" > /dev/null 2>&1
            fi
        done
    fi

    # 4. シェル固有設定
    if [ -n "$ZSH_VERSION" ]; then
        _loader_zsh_dir="$DOTFILES_PATH/zsh"
        [ -r "$_loader_zsh_dir/hooks.zsh" ]   && source "$_loader_zsh_dir/hooks.zsh"   > /dev/null 2>&1
        [ -r "$_loader_zsh_dir/options.zsh" ] && source "$_loader_zsh_dir/options.zsh" > /dev/null 2>&1
        [ -r "$_loader_zsh_dir/aliases.zsh" ] && source "$_loader_zsh_dir/aliases.zsh" > /dev/null 2>&1
        [ -r "$_loader_zsh_dir/_p10k.zsh" ]   && source "$_loader_zsh_dir/_p10k.zsh"   > /dev/null 2>&1
        alias reload='exec zsh -l'
    elif [ -n "$BASH_VERSION" ]; then
        if [ "$EUID" -eq 0 ]; then
            export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
        fi
        alias reload='source ~/.bashrc'
    fi

    # 5. クリーンアップ
    unset _loader_f _loader_common_dir _loader_zsh_dir
fi
