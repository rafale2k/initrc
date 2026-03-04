#!/bin/bash
# shellcheck shell=bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
    [[ $- != *i* ]] && return 0
    [ "$EUID" -eq 0 ] && return 0
    [ "$TERM" = "linux" ] && return 0

    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
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
if [ -n "${ZSH_VERSION:-}" ]; then
    alias reload='exec zsh -l'
elif [ -n "$BASH_VERSION" ]; then
    alias reload='source ~/.bashrc'
fi

# 基本操作
alias s='sudo -i'
alias si='sudo -i'
alias ss='sudo -s'
alias path='echo -e "${PATH//:/\n}"'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- モダンコマンド置換 (eza / bat) ---
# ※ アンインストール後の再インストールでも確実に動くよう $HOME 基準で設定

# 1. eza (ls replacement)
if [ -x "$HOME/bin/eza" ]; then
    unalias ls ll la lt 2>/dev/null
    alias ls='$HOME/bin/eza --icons --group-directories-first'
    alias ll='$HOME/bin/eza -alF --icons --git'
    alias la='$HOME/bin/eza -a --icons --group-directories-first'
    alias lt='$HOME/bin/eza --tree -a --icons --git --ignore-glob=".git"'
else
    alias ls='ls --color=auto'
fi

# 2. bat (cat replacement)
if [ -x "$HOME/bin/bat" ]; then
    unalias cat 2>/dev/null
    alias cat='$HOME/bin/bat --paging=never --theme="Monokai Extended"'
    alias bat='$HOME/bin/bat'
elif command -v batcat &> /dev/null; then
    unalias cat 2>/dev/null
    alias cat='batcat --paging=never'
    alias bat='batcat'
fi

# 3. fd-find
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# --- Git 基本エイリアス (loaderが失敗しても最低限動くように) ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# ---------------------------------------------------------
# Nano Wrapper & Selector
# ---------------------------------------------------------
n() {
    local file bat_cmd
    if command -v batcat &> /dev/null; then
        bat_cmd="batcat"
    elif command -v bat &> /dev/null; then
        bat_cmd="bat"
    else
        bat_cmd="cat"
    fi

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

# ---------------------------------------------------------
# 外部連携 (Monokai Palette / Clipboard)
# ---------------------------------------------------------
if [ -f "$DOTFILES_PATH/scripts/install_functions.sh" ]; then
    source "$DOTFILES_PATH/scripts/install_functions.sh"
    install_monokai_palette "$DOTFILES_PATH" > /dev/null 2>&1
fi

alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'

localip() {
    hostname -I | awk '{print $1}'
}

alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

clipcopy() {
    local content
    [[ $# -eq 0 ]] && content=$(cat) || content=$(cat "$1")

    if [ -f /.dockerenv ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        local base64_str
        base64_str=$(echo -n "$content" | base64 | tr -d '\n')
        printf "\e]52;c;%s\a" "$base64_str"
        echo "📋 [OSC 52] Copied to host clipboard"
        return
    fi

    case "$(uname)" in
        "Darwin") echo -n "$content" | pbcopy ;;
        "Linux")
            if grep -qi Microsoft /proc/version 2>/dev/null; then
                echo -n "$content" | clip.exe
            elif command -v xclip >/dev/null 2>&1; then
                echo -n "$content" | xclip -selection clipboard
            else
                local b64
                b64=$(echo -n "$content" | base64 | tr -d '\n')
                printf "\e]52;c;%s\a" "$b64"
            fi
            ;;
    esac
}
