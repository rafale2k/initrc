#!/bin/bash
# ------------------------------------------------------------------------------
# .bashrc: SRE Edition (Stability & Aesthetics) - Final Check Passed
# ------------------------------------------------------------------------------

# 1. 環境変数の読み込み
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env
[[ -f /root/.dotfiles_env ]] && source /root/.dotfiles_env

# 2. パス・環境変数定義
export DOTPATH="${DOTPATH:-$HOME/dotfiles}"
export TERM=xterm-256color

# PATHの整理（重複を防ぎつつ基本パスを確保）
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH="$HOME/.local/bin:$DOTPATH/bin:$PATH"

# 3. 共通ローダーの呼び出し (common系: ask, dask, color definitions)
if [ -f "$DOTPATH/common/loader.sh" ]; then
    source "$DOTPATH/common/loader.sh"
fi

# 4. Bash 固有設定と OMB の起動
# ※ options.sh の中で OMB の起動とカスタムテーマのリンクを行う
if [ -f "$DOTPATH/bash/options.sh" ]; then
    source "$DOTPATH/bash/options.sh"
fi

# 5. 便利関数の読み込み (copyfile等)
[ -f "$DOTPATH/bash/functions.sh" ] && source "$DOTPATH/bash/functions.sh"
