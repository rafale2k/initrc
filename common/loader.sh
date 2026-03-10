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
DOTPATH="$(cd "$_ld_script_dir/.." && pwd)"
export DOTPATH
export DOTFILES_PATH="$DOTPATH"
export DOTFILES_ROOT="$DOTPATH"

# 2. PATH の設定 ($HOME/bin を最優先)
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# 3. .env の読み込み
if [ -f "$DOTPATH/configs/.env" ]; then
    source "$DOTPATH/configs/.env" > /dev/null 2>&1
fi

# 4. 共通設定 (_*.sh) の一括読み込み
_ld_common_dir="$DOTPATH/common"
if [ -d "$_ld_common_dir" ]; then
    # nullglob 相当の処理を POSIX 準拠で書く
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        # ファイルが実在する場合のみ source
        if [ -f "$_ld_f" ]; then
            # loader.sh 自体は source しない (念のため)
            case "$_ld_f" in
                *loader.sh) continue ;;
            esac
            source "$_ld_f"
        fi
    done
fi

# Docker の権限エラー (Permission Denied) 回避
export DOCKER_CONFIG="$HOME/.docker_temp"
[ ! -d "$DOCKER_CONFIG" ] && mkdir -p "$DOCKER_CONFIG"

# OS判定
OS_TYPE=$(uname -s)

if [ "$OS_TYPE" = "Darwin" ]; then
    # Mac: Brewの標準パスを静的に追加
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
else
    # Linux: エイリアス設定
    if command -v batcat >/dev/null 2>&1; then alias bat='batcat'; fi
    if command -v fdfind >/dev/null 2>&1; then alias fd='fdfind'; fi
fi

# 自作の self_heal を読み込み
if [ -f "$DOTPATH/scripts/self_heal.sh" ]; then
    source "$DOTPATH/scripts/self_heal.sh"
    # 起動時にバックグラウンドで実行（プロンプト表示を待たせない）
    dcheck >/dev/null 2>&1 &!
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
    if [ "${EUID:-}" -eq 0 ]; then
        export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]@\h\[\e[0m\]:\[\e[01;34m\]\w\[\e[00m\]# '
    fi
    alias reload='source ~/.bashrc'
fi

if command -v zoxide >/dev/null 2>&1; then
    # zsh の場合
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    # bash の場合
    elif [ -n "${BASH_VERSION:-}" ]; then
        eval "$(zoxide init bash)"
    fi
    
    # 共通のエイリアス (cd を z に置き換える)
    alias j='zi'  # インタラクティブ検索 (fzf連携)
fi

unset _ld_f _ld_common_dir _ld_zsh_dir _ld_current_script _ld_script_dir
