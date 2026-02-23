#!/bin/bash

# --- Git Aliases ---
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate'
alias gnw='git diff -w --no-ext-diff' # 空白を無視してdiffを確認

# --- Git Main Branch Sync ---
# main または master に戻って最新を pull する
alias gms='git checkout $(git symbolic-ref --short refs/remotes/origin/HEAD | sed "s/origin\///") && git pull'

# --- GCM (Git Commit Message AI) ---
# 先ほど作成した gcm 関数をここに定義するか、
# もし bin/gcm に切り出したなら、パスが通っていればOKです。
# ここでは bin/gcm を優先する形でエイリアスを確認。
if [ -f "$HOME/dotfiles/bin/gcm" ]; then
    alias gcm="$HOME/dotfiles/bin/gcm"
fi
