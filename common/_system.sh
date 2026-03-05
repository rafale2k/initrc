#!/bin/bash
# shellcheck shell=bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# --- 1. コマンドの吸収 (名前の重複を避ける) ---
# エイリアスを定義する前に、既存の同名エイリアスを解除しておく
unalias fd fdfind bat batcat ls ll la lt cat n l 2>/dev/null

# --- 2. ターミナル配色制御 ---
set_tokyo_night_colors() {
    [[ $- != *i* ]] && return 0
    printf "\e]4;0;#1a1b26\a"; printf "\e]4;8;#414868\a"
    printf "\e]4;1;#f7768e\a"; printf "\e]4;9;#f7768e\a"
    printf "\e]4;2;#9ece6a\a"; printf "\e]4;10;#9ece6a\a"
    printf "\e]4;3;#e0af68\a"; printf "\e]4;11;#e0af68\a"
    printf "\e]4;4;#7aa2f7\a"; printf "\e]4;12;#7aa2f7\a"
    printf "\e]4;5;#bb9af7\a"; printf "\e]4;13;#bb9af7\a"
    printf "\e]4;6;#7dcfff\a"; printf "\e]4;14;#7dcfff\a"
    printf "\e]4;7;#a9b1d6\a"; printf "\e]4;15;#c0caf5\a"
    printf "\e]11;#1a1b26\a"; printf "\e]10;#a9b1d6\a"; printf "\e]12;#7aa2f7\a"
}

set_monokai_colors() {
    [[ $- != *i* ]] && return 0
    printf "\e]4;0;#272822\a"; printf "\e]4;8;#75715e\a"
    printf "\e]4;1;#f92672\a"; printf "\e]4;9;#f92672\a"
    printf "\e]4;2;#a6e22e\a"; printf "\e]4;10;#a6e22e\a"
    printf "\e]4;3;#f4bf75\a"; printf "\e]4;11;#f4bf75\a"
    printf "\e]4;4;#66d9ef\a"; printf "\e]4;12;#66d9ef\a"
    printf "\e]4;5;#ae81ff\a"; printf "\e]4;13;#ae81ff\a"
    printf "\e]4;6;#a1efe4\a"; printf "\e]4;14;#a1efe4\a"
    printf "\e]4;7;#f8f8f2\a"; printf "\e]4;15;#f9f8f5\a"
    printf "\e]11;#272822\a"; printf "\e]10;#f8f8f2\a"; printf "\e]12;#f92672\a"
}

# 配色適用
if [ "$EUID" -eq 0 ]; then
    set_tokyo_night_colors
else
    set_monokai_colors
fi

# --- 3. 環境変数 (eza / LS_COLORS) ---
export EZA_COLORS="ur=32:gu=32:gr=33:gw=33:tr=38;5;244:sn=35:nb=35:nm=35:da=38;5;248:di=36:fi=0:ln=35:pi=33:so=35:bd=33;46:cd=33;43:or=31;40:mi=31;40:ex=32:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44"
export LS_COLORS=$EZA_COLORS

# --- 4. 関数定義 (エイリアスより先に定義するのが鉄則) ---

# 高機能ツリー表示
lt() {
    local depth=""
    [[ "$1" =~ ^[0-9]+$ ]] && { depth="--level=$1"; shift; }
    # エイリアスを避けるためフルパスまたは command を使用
    if [ -x "$HOME/bin/eza" ]; then
        "$HOME/bin/eza" --tree -a --icons --git --ignore-glob=".git" ${depth:+"$depth"} "$@"
    else
        command ls -R "$@"
    fi
}

# Nano Wrapper
n() {
    local file bat_cmd fd_cmd bg_orig
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")
    fd_cmd=$(command -v fdfind || command -v fd || echo "find")
    bg_orig=$([ "$EUID" -eq 0 ] && echo "#1a1b26" || echo "#272822")

    if [ $# -gt 0 ]; then
        command nano "$@"
    else
        if command -v fzf &> /dev/null; then
            file=$($fd_cmd --type f --hidden --exclude .git 2>/dev/null | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}")
            [ -n "$file" ] && command nano "$file"
        else
            command nano
        fi
    fi
    printf "\e]4;0;%s\a" "$bg_orig" # 背景色復元
}

# ログ・プロセス監視
l() {
    if [ $# -eq 0 ]; then
        local log_file
        log_file=$(find . -maxdepth 2 -name "*.log" 2>/dev/null | fzf --prompt="Watch Log > " --height=40% --reverse)
        if [ -n "$log_file" ]; then
            echo -e "\033[35m-- Monitoring: $log_file --\033[0m"
            command -v ccze &> /dev/null && tail -f "$log_file" | ccze -A || tail -f "$log_file"
        else
            echo -e "\033[32m-- System Resource Monitor --\033[0m"
            if command -v htop &> /dev/null; then htop; else top -u "$USER"; fi
        fi
        return
    fi
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        echo -e "\033[36m-- Process using port $1 (sudo) --\033[0m"
        sudo lsof -i ":$1" || echo "No process found on port $1"
        return
    fi
    echo -e "\033[33m-- Searching process: $1 --\033[0m"
    local pids
    pids=$(pgrep -d, -f -i "$1")
    if [ -n "$pids" ]; then
        ps -up "$pids" | grep --color=always -i -E "$1|$"
    else
        echo "No process found matching: $1"
    fi
}

# --- 5. エイリアス定義 (最後に書く) ---
alias reload='[ -n "$ZSH_VERSION" ] && exec zsh -l || source ~/.bashrc'
alias s='sudo -i'
alias si='sudo -i'
alias ss='sudo -s'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias path='echo -e "${PATH//:/\n}"'
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'
alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

# モダン置換
command -v fdfind &> /dev/null && alias fd='fdfind'
if [ -x "$HOME/bin/eza" ]; then
    alias ls='$HOME/bin/eza --icons --group-directories-first'
    alias ll='$HOME/bin/eza -alF --icons --git'
    alias la='$HOME/bin/eza -a --icons --group-directories-first'
fi
if [ -x "$HOME/bin/bat" ]; then
    alias cat='$HOME/bin/bat --paging=never --theme="Monokai Extended"'
    alias bat='$HOME/bin/bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias bat='batcat'
fi
