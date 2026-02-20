#!/bin/bash

# ==========================================
# 1. ターミナル配色制御 (Tokyo Night)
# ==========================================
# ターミナルの色を Tokyo Night に染める最強魔法
set_tokyo_night_colors() {
    # インタラクティブシェルでない場合は実行しない
    [[ $- != *i* ]] && return

    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" ]]; then
        if [ "$EUID" -ne 0 ]; then
            # --- 16色パレット定義 (0-15番) ---
            printf "\033]4;0;#1a1b26\007"  # Background
            printf "\033]4;8;#414868\007"  # Bright Black (Comments)
            printf "\033]4;1;#f7768e\007"  # Red
            printf "\033]4;9;#f7768e\007"  # Bright Red
            printf "\033]4;2;#9ece6a\007"  # Green
            printf "\033]4;10;#9ece6a\007" # Bright Green
            printf "\033]4;3;#e0af68\007"  # Yellow
            printf "\033]4;11;#e0af68\007" # Bright Yellow
            printf "\033]4;4;#7aa2f7\007"  # Blue
            printf "\033]4;12;#7aa2f7\007" # Bright Blue
            printf "\033]4;5;#bb9af7\007"  # Magenta
            printf "\033]4;13;#bb9af7\007" # Bright Magenta
            printf "\033]4;6;#7dcfff\007"  # Cyan
            printf "\033]4;14;#7dcfff\007" # Bright Cyan
            printf "\033]4;7;#a9b1d6\007"  # White
            printf "\033]4;15;#c0caf5\007" # Bright White

            # --- 直接指定 (トドメ) ---
            printf "\e]11;#1a1b26\a" # 背景色
            printf "\e]10;#a9b1d6\a" # 文字色
            printf "\e]12;#7aa2f7\a" # カーソル色
        fi
    fi
}

# 読み込み時に一度実行
set_tokyo_night_colors

# 基本エイリアス
alias s='sudo -i; set_tokyo_night_colors'
alias exit='set_tokyo_night_colors; exit'
alias ..='cd ..'
alias ll='ls -alF --color=auto'
alias b='cd -'
alias path='echo -e ${PATH//:/\\n}'
alias lt='tree -C -L 3'

# bat / cat 切り替え
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

mkcd() { mkdir -p "$1" && cd "$1"; }
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
