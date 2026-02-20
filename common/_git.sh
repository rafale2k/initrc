#!/bin/bash
# Git エイリアス & 関数
unalias gcm 2>/dev/null

alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push origin main'
alias gl='git lg'
alias gquick='git add -A && git commit -m "quick update: $(date "+%Y-%m-%d %H:%M:%S")" && git push origin main'

gcm() {
    if ! command -v fzf &> /dev/null; then
        echo -n "Message: "; read msg; [ -n "$msg" ] && git commit -m "$msg"; return
    fi
    local type=$(printf "feat: 新機能\nfix: バグ修正\ndocs: ドキュメント修正\nstyle: 整形\nrefactor: リファクタリング\nchore: 雑事" | fzf --height 40% --reverse --prompt="Commit Type > " | cut -d':' -f1)
    [ -z "$type" ] && return
    echo -n "Message: "; read msg; [ -z "$msg" ] && return
    git commit -m "$type: $msg"
}
