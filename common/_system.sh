#!/bin/bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# ターミナル配色制御 (Tokyo Night)
# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
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

            # --- 直接指定 ---
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
    local file
    local bat_cmd

    # bat コマンド判別 (プレビュー用)
    if command -v batcat &> /dev/null; then
        bat_cmd="batcat"
    elif command -v bat &> /dev/null; then
        bat_cmd="bat"
    else
        bat_cmd="cat"
    fi

    # 引数がある場合は、そのまま nano で開く
    if [ $# -gt 0 ]; then
        printf "\e]4;0;#272822\a"  # Monokai背景へ
        nano "$@"
        printf "\e]4;0;#1a1b26\a"  # Tokyo Night背景へ戻す
    else
        # 引数がない場合は fzf でファイルを選択
        # fd があれば使い、なければ find でリストアップ
        if command -v fdfind &> /dev/null || command -v fd &> /dev/null; then
            local fd_bin=$(command -v fdfind || command -v fd)
            file=$($fd_bin --type f --hidden --exclude .git | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}" --preview-window=right:60%)
        else
            file=$(find . -maxdepth 4 -not -path '*/.*' -o -path './.*' -not -name "." | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}" --preview-window=right:60%)
        fi

        # ファイルが選択されたら Monokai 背景で開く
        if [ -n "$file" ]; then
            printf "\e]4;0;#272822\a"
            nano "$file"
            printf "\e]4;0;#1a1b26\a"
        fi
    fi
}

# モダンコマンド置換 (eza)
if [ -f /usr/local/bin/eza ]; then
    alias ls='/usr/local/bin/eza --icons --group-directories-first'
    alias ll='/usr/local/bin/eza -alF --icons --git'
    alias lt='/usr/local/bin/eza -T -L 3 --icons --git'
    alias la='/usr/local/bin/eza -a --icons --group-directories-first' # 隠しファイル込み
else
    alias ll='ls -alF --color=auto'
    alias lt='tree -C -L 3'
    alias la='ls -la --color=auto'
fi

# モダンコマンド置換 (bat)
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

# Ubuntu系なら fdfind を fd として使えるようにする
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# ユーティリティ
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'
alias localip="hostname -I | cut -d' ' -f1"
alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

