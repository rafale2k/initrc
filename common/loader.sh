#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# 1. パスの自動確定
if [ -n "${ZSH_VERSION:-}" ]; then
    # shellcheck disable=SC2296
    _ld_current_script="${(%):-%x}"
else
    _ld_current_script="${BASH_SOURCE[0]}"
fi

_ld_script_dir="$(cd "$(dirname "$_ld_current_script")" && pwd)"
# SC2155 対策: 宣言と代入を分離
DOTPATH="$(cd "$_ld_script_dir/.." && pwd)"
export DOTPATH
export DOTFILES_PATH="$DOTPATH"
export DOTFILES_ROOT="$DOTPATH"

# 2. PATH の設定
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) export PATH="$HOME/bin:$PATH" ;;
esac

# 3. .env の読み込み
if [ -f "$DOTPATH/configs/.env" ]; then
    source "$DOTPATH/configs/.env" > /dev/null 2>&1
fi

# 4. 共通設定 (_*.sh) の一括読み込み
_ld_common_dir="$DOTPATH/common"
if [ -d "$_ld_common_dir" ]; then
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        # loader.sh 自体は source しない
        [[ "$_ld_f" == *"loader.sh" ]] && continue
        if [ -r "$_ld_f" ]; then
            source "$_ld_f"
        fi
    done
fi

# OS判定
OS_TYPE=$(uname -s)

# $HOME/bin を最優先に
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

if [ "$OS_TYPE" = "Darwin" ]; then
    # Mac: Brewのパスを動的に追加
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    # エイリアスは使わず、PATHの優先順位に任せる
else
    # Linux: 名前が違うものだけエイリアス
    if command -v batcat >/dev/null 2>&1; then
        alias bat='batcat'
    fi
    if command -v fdfind >/dev/null 2>&1; then
        alias fd='fdfind'
    fi
fi

# 5. シェル別の設定
if [ -n "${ZSH_VERSION:-}" ]; then
    _ld_zsh_dir="$DOTPATH/zsh"
    [ -r "$_ld_zsh_dir/hooks.zsh" ]   && source "$_ld_zsh_dir/hooks.zsh"
    [ -r "$_ld_zsh_dir/options.zsh" ] && source "$_ld_zsh_dir/options.zsh"
    [ -r "$_ld_zsh_dir/aliases.zsh" ] && source "$_ld_zsh_dir/aliases.zsh"
    [ -r "$_ld_zsh_dir/_p10k.zsh" ]   && source "$_ld_zsh_dir/_p10k.zsh"
    alias reload='exec zsh -l'
elif [ -n "${BASH_VERSION:-}" ]; then
    [ "${EUID:-}" -eq 0 ] && export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    alias reload='source ~/.bashrc'
fi

unset _ld_f _ld_common_dir _ld_zsh_dir _ld_current_script _ld_script_dir
