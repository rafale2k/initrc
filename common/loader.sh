#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2034

# --- 🚀 INITRC_LOADER_GUARD ---
if [ -n "${INITRC_LOADER_LOADED:-}" ]; then
    return 0 2>/dev/null
fi
export INITRC_LOADER_LOADED=1

# 1. パスの自動確定 (絶対パスを排除)
# どのユーザーがどこにインストールしても、このファイルの位置からルートを割り出す
if [ -n "${ZSH_VERSION:-}" ]; then
    # shellcheck disable=SC2296
    _ld_current_script="${(%):-%x}"
else
    _ld_current_script="${BASH_SOURCE[0]}"
fi

_ld_script_dir="$(cd "$(dirname "$_ld_current_script")" && pwd)"
# 分離して代入
DOTFILES_PATH="$(cd "$_ld_script_dir/.." && pwd)"
export DOTFILES_PATH

# 2. PATH の設定
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) export PATH="$HOME/bin:$PATH" ;;
esac

# 3. .env の読み込み
if [ -f "$DOTFILES_PATH/configs/.env" ]; then
    source "$DOTFILES_PATH/configs/.env" > /dev/null 2>&1
fi

# 4. 共通設定 (_*.sh) の一括読み込み
_ld_common_dir="$DOTFILES_PATH/common"
if [ -d "$_ld_common_dir" ]; then
    for _ld_f in "$_ld_common_dir"/_*.sh; do
        # 自分自身 (loader.sh) は読み込まない
        [[ "$_ld_f" == *"loader.sh" ]] && continue
        
        if [ -r "$_ld_f" ]; then
            # 👇 ここ！この一行が消えてたから出なくなったんや
            echo "📖 Loading: $_ld_f" 
            source "$_ld_f"
        fi
    done
fi

# 5. Zsh 特有の設定読み込み
if [ -n "${ZSH_VERSION:-}" ]; then
    _ld_zsh_dir="$DOTFILES_PATH/zsh"
    [ -r "$_ld_zsh_dir/hooks.zsh" ]   && source "$_ld_zsh_dir/hooks.zsh"
    [ -r "$_ld_zsh_dir/options.zsh" ] && source "$_ld_zsh_dir/options.zsh"
    [ -r "$_ld_zsh_dir/aliases.zsh" ] && source "$_ld_zsh_dir/aliases.zsh"
    [ -r "$_ld_zsh_dir/_p10k.zsh" ]   && source "$_ld_zsh_dir/_p10k.zsh"
    
    alias reload='exec zsh -l'
elif [ -n "${BASH_VERSION:-}" ]; then
    [ "${EUID:-}" -eq 0 ] && export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    alias reload='source ~/.bashrc'
fi

# 後片付け
unset _ld_f _ld_common_dir _ld_zsh_dir _ld_current_script _ld_script_dir
