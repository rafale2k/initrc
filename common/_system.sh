#!/bin/bash
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

    # 2. xterm 互換環境でのみ色を設定
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
        # --- 16色パレット定義 ---
        printf "\033]4;0;#1a1b26\007"
        printf "\033]4;8;#414868\007"
        printf "\033]4;1;#f7768e\007"
        printf "\033]4;9;#f7768e\007"
        printf "\033]4;2;#9ece6a\007"
        printf "\033]4;10;#9ece6a\007"
        printf "\033]4;3;#e0af68\007"
        printf "\033]4;11;#e0af68\007"
        printf "\033]4;4;#7aa2f7\007"
        printf "\033]4;12;#7aa2f7\007"
        printf "\033]4;5;#bb9af7\007"
        printf "\033]4;13;#bb9af7\007"
        printf "\033]4;6;#7dcfff\007"
        printf "\033]4;14;#7dcfff\007"
        printf "\033]4;7;#a9b1d6\007"
        printf "\033]4;15;#c0caf5\007"

        # --- 特殊色 ---
        printf "\033]11;#1a1b26\007"
        printf "\033]10;#a9b1d6\007"
        printf "\033]12;#7aa2f7\007"
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
# SC2016対策: シングルクォート内で展開させない意図を明確に
alias path='echo -e "${PATH//:/\n}"'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tokyo='printf "\033]4;0;#1a1b26\007"'

# モダンコマンド置換 (eza)
EZA_BIN=$(command -v eza || command -v /usr/local/bin/eza 2>/dev/null)
if [ -x "$EZA_BIN" ]; then
    # SC2139対策: 定義時の展開を防ぐためバックスラッシュを使用
    alias ls="\"$EZA_BIN\" --icons --group-directories-first"
    alias ll="\"$EZA_BIN\" -alF --icons --git"
    alias lt="\"$EZA_BIN\" --tree -a --icons --git --ignore-glob=\".git\""
    alias lt2="\"$EZA_BIN\" --tree -a --icons --ignore-glob=\".git\" --level=2"
    alias la="\"$EZA_BIN\" -a --icons --group-directories-first"
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
# Nano Wrapper & Selector (SC1072, SC1073 修正済み)
# ---------------------------------------------------------
n() {
    local file bat_cmd
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")

    if [ $# -gt 0 ]; then
        [ "$EUID" -ne 0 ] && printf "\033]4;0;#272822\007"
        command nano "$@"
        [ "$EUID" -ne 0 ] && printf "\033]4;0;#1a1b26\007"
    else
        # fzf がある場合のみ実行 (括弧の閉じ忘れを修正)
        if command -v fzf &> /dev/null; then
            file=$(fdfind --type f --hidden --exclude .git 2>/dev/null | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}")
            if [ -n "$file" ]; then
                [ "$EUID" -ne 0 ] && printf "\033]4;0;#272822\007"
                command nano "$file"
                [ "$EUID" -ne 0 ] && printf "\033]4;0;#1a1b26\007"
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
        base64_str=$(echo -n "$content" | base64 | tr -d '\n')
        printf "\033]52;c;%s\007" "$base64_str"
        echo "📋 [OSC 52] Copied to host clipboard"
        return
    fi

    case "$(uname)" in
        "Darwin")
            echo -n "$content" | pbcopy
            echo "📋 [macOS] Copied via pbcopy"
            ;;
        "Linux")
            # SC2143対策: grep -q を使用
            if grep -qi Microsoft /proc/version 2>/dev/null; then
                echo -n "$content" | clip.exe
                echo "📋 [WSL] Copied via clip.exe"
            elif command -v xclip >/dev/null 2>&1; then
                echo -n "$content" | xclip -selection clipboard
                echo "📋 [Linux] Copied via xclip"
            else
                local b64
                b64=$(echo -n "$content" | base64 | tr -d '\n')
                printf "\033]52;c;%s\007" "$b64"
                echo "📋 [Fallback] Tried OSC 52"
            fi
            ;;
    esac
}

if alias clipcopy >/dev/null 2>&1; then
    unalias clipcopy
fi
