#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# --- 🚀 INITRC_LOADER_GUARD ---
# 重複読み込みを物理的に防ぐ
if [ -z "$INITRC_LOADER_LOADED" ]; then
    export INITRC_LOADER_LOADED=1

    # 1. パスの確定
    # BASH_SOURCE が使えない環境（一部の古いシェル等）へのフォールバック
    export DOTFILES_PATH
    if [ -n "$BASH_SOURCE" ]; then
        DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    elif [ -n "$ZSH_NAME" ]; then
        DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
    else
        # 最終手段（パスが解決できない場合は /dev/null へ逃がす）
        DOTFILES_PATH="${HOME}/.dotfiles"
    fi

    # 2. ローカル環境変数を読み込む (configs/.env)
    if [ -f "$DOTFILES_PATH/configs/.env" ]; then
        # shellcheck source=/dev/null
        source "$DOTFILES_PATH/configs/.env" > /dev/null 2>&1
    fi

    # 3. 共通スクリプトの自動読み込み (_*.sh)
    local common_dir="$DOTFILES_PATH/common"
    if [ -d "$common_dir" ]; then
        for f in "$common_dir"/_*.sh; do
            if [ -r "$f" ]; then
                # shellcheck source=/dev/null
                source "$f" > /dev/null 2>&1
            fi
        done
    fi

    # 4. 各シェル固有設定の読み込み
    if [ -n "$ZSH_VERSION" ]; then
        local zsh_dir="$DOTFILES_PATH/zsh"
        [ -r "$zsh_dir/hooks.zsh" ]   && source "$zsh_dir/hooks.zsh"   > /dev/null 2>&1
        [ -r "$zsh_dir/options.zsh" ] && source "$zsh_dir/options.zsh" > /dev/null 2>&1
        [ -r "$zsh_dir/aliases.zsh" ] && source "$zsh_dir/aliases.zsh" > /dev/null 2>&1
        [ -r "$zsh_dir/_p10k.zsh" ]   && source "$zsh_dir/_p10k.zsh"   > /dev/null 2>&1
        
        alias reload='exec zsh -l'

    elif [ -n "$BASH_VERSION" ]; then
        # shellcheck disable=SC2034
        local bash_dir="$DOTFILES_PATH/bash"
        
        export PROMPT_COMMAND=""
        if [ "$EUID" -eq 0 ]; then
            export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
        fi
        alias reload='source ~/.bashrc'
    fi

    # 5. クリーンアップ (local変数でないもの)
    unset f common_dir zsh_dir bash_dir
fi
