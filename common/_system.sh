k#!/bin/bash
# shellcheck shell=bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
    # 1. 非インタラクティブシェルや root の場合は色設定をスキップ
    [[ $- != *i* ]] && return 0
    [ "$EUID" -eq 0 ] && return 0
    [ "$TERM" = "linux" ] && return 0

    # 2. xterm 互換環境でのみ色を設定 (制御文字をエスケープ形式に変更)
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
        # --- 16色パレット定義 ---
        printf "\e]4;0;#1a1b26\a"
        printf "\e]4;8;#414868\a"
        printf "\e]4;1;#f7768e\a"
        printf "\e]4;9;#f7768e\a"
        printf "\e]4;2;#9ece6a\a"
        printf "\e]4;10;#9ece6a\a"
        printf "\e]4;3;#e0af68\a"
        printf "\e]4;11;#e0af68\a"
        printf "\e]4;4;#7aa2f7\a"
        printf "\e]4;12;#7aa2f7\a"
        printf "\e]4;5;#bb9af7\a"
        printf "\e]4;13;#bb9af7\a"
        printf "\e]4;6;#7dcfff\a"
        printf "\e]4;14;#7dcfff\a"
        printf "\e]4;7;#a9b1d6\a"
        printf "\e]4;15;#c0caf5\a"

        # --- 特殊色 ---
        printf "\e]11;#1a1b26\a"
        printf "\e]10;#a9b1d6\a"
        printf "\e]12;#7aa2f7\a"
    fi
}

set_tokyo_night_colors

# ==========================================
# エイリアス & 関数定義
# ==========================================

# シェル再起動
if [ -n "$ZSH_VERSION" ]; then
    alias reload='exec zsh -l'
elif [ -n "$BASH_VERSION" ]; then
    alias reload='source ~/.bashrc'
fi

# 基本操作
alias s='sudo -i'
alias si='sudo -i'
alias ss='sudo -s'
# SC2016対策: PATH展開を遅延させるためシングルクォートを使用
alias path='echo -e "${PATH//:/\n}"'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tokyo='printf "\e]4;0;#1a1b26\a"'

# モダンコマンド置換 (eza)
EZA_BIN=$(command -v eza || command -v /usr/local/bin/eza 2>/dev/null)
if [ -x "$EZA_BIN" ]; then
    # SC2139対策: ダブルクォートをやめ、シングルクォートで定義することで実行時に評価させる
    alias ls='$EZA_BIN --icons --group-directories-first'
    alias ll='$EZA_BIN -alF --icons --git'
    alias lt='$EZA_BIN --tree -a --icons --git --ignore-glob=".git"'
    alias lt2='$EZA_BIN --tree -a --icons --ignore-glob=".git" --level=2'
    alias la='$EZA_BIN -a --icons --group-directories-first'
else
    alias ll='ls -alF --color=auto'
    alias la='ls -la --color=auto'
fi

# モダンコマンド置換 (bat)
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# ---------------------------------------------------------
# Nano Wrapper & Selector
# ---------------------------------------------------------
n() {
    local file bat_cmd
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")

    if [ $# -gt 0 ]; then
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
        command nano "$@"
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
    else
        if command -v fzf &> /dev/null; then
            file=$(fdfind --type f --hidden --exclude .git 2>/dev/null | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}")
            if [ -n "$file" ]; then
                [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
                command nano "$file"
                [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
            fi
        else
            command nano
        fi
    fi
}

# ユーティリティ
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'

# SC2142対策: positional parameterを含むエイリアスは関数にする
localip() {
    hostname -I | awk '{print $1}'
}

alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

# --- クリップボード連携 ---
clipcopy() {
    local content
    if [[ $# -eq 0 ]]; then
        content=$(cat)
    else
        content=$(cat "$1")
    fi

    if [ -f /.dockerenv ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        local base64_str
        # SC2155対策: 宣言と代入を分離
        base64_str=$(echo -n "$content" | base64 | tr -d '\n')
        printf "\e]52;c;%s\a" "$base64_str"
        echo "📋 [OSC 52] Copied to host clipboard"
        return
    fi

    case "$(uname)" in
        "Darwin")
            echo -n "$content" | pbcopy
            echo "📋 [macOS] Copied via pbcopy"
            ;;
        "Linux")
            if grep -qi Microsoft /proc/version 2>/dev/null; then
                echo -n "$content" | clip.exe
                echo "📋 [WSL] Copied via clip.exe"
            elif command -v xclip >/dev/null 2>&1; then
                echo -n "$content" | xclip -selection clipboard
                echo "📋 [Linux] Copied via xclip"
            else
                local b64
                b64=$(echo -n "$content" | base64 | tr -d '\n')
                printf "\e]52;c;%s\a" "$b64"
                echo "📋 [Fallback] Tried OSC 52"
            fi
            ;;
    esac
}

if alias clipcopy >/dev/null 2>&1; then
    unalias clipcopy
fi
