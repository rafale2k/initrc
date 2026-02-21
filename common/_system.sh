#!/bin/bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
    [[ $- != *i* ]] && return
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" ]]; then
        if [ "$EUID" -ne 0 ]; then
            printf "\033]4;0;#1a1b26\007"
            # ... (中略: カラーパレット設定) ...
            printf "\e]11;#1a1b26\a" # 背景色
            printf "\e]10;#a9b1d6\a" # 文字色
            printf "\e]12;#7aa2f7\a" # カーソル色
        fi
    fi
}
set_tokyo_night_colors

# 基本エイリアス
alias s='sudo -i; set_tokyo_night_colors'
alias exit='set_tokyo_night_colors; exit'
alias si='sudo -i; set_tokyo_night_colors'
alias ss='sudo -s; set_tokyo_night_colors'
alias path='echo -e ${PATH//:/\\n}'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tokyo='printf "\e]4;0;#1a1b26\a"'

# Nano (Monokai背景)
n() {
    printf "\e]4;0;#272822\a"
    nano "$@"
    printf "\e]4;0;#1a1b26\a"
}

# モダンコマンド置換 (eza)
if [ -f /usr/local/bin/eza ]; then
    alias ls='/usr/local/bin/eza --icons --group-directories-first'
    alias ll='/usr/local/bin/eza -alF --icons --git'
    alias lt='/usr/local/bin/eza -T -L 3 --icons --git'
else
    alias ll='ls -alF --color=auto'
    alias lt='/usr/local/bin/eza -C -L 3'
fi

# モダンコマンド置換 (bat)
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

# ユーティリティ
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'
alias localip="hostname -I | cut -d' ' -f1"
alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'
