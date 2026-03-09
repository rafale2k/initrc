#!/bin/bash

# --- 1. Git Basic Aliases ---
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push'
alias gpm='git push origin main'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gdc='git diff --cached'
alias gundo='git reset --soft HEAD~1'
alias gfix='git commit --amend --no-edit'
unalias gl 2>/dev/null
alias gl='git log --oneline --graph --decorate'

# --- 2. Git Main Sync ---
alias gms='git stash && git checkout $(git symbolic-ref --short refs/remotes/origin/HEAD | sed "s/origin\///") && git pull && git stash pop 2>/dev/null || true'

# --- 3. git-extras & Power Aliases ---
alias gsum='git summary'
alias gcount='git effort --above 5'
alias gline='git log --pretty=format:"%C(yellow)%h%Creset %C(magenta)%ad%Creset %s %C(cyan)(%an)%Creset" --date=short'
alias ggraph='git log --graph --all --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold red)- %an%C(reset)%C(bold yellow)%d%C(reset)" --abbrev-commit --date=relative'

gtoday() {
    if command -v git-standup >/dev/null 2>&1; then git standup "$@";
    else git log --since="00:00:00" --all --no-merges --oneline --author="$(git config user.email)"; fi
}

# --- 4. Cleanup ---
alias gcl='git branch --merged | grep -vE "^\*|master|main|develop" | xargs -r git branch -d'

# --- 5. Functions & AI ---
gquick() {
    local msg="${1:-quick update: $(date '+%Y-%m-%d %H:%M:%S')}"
    git add -A && git commit -m "$msg"
    local branch; branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    git push origin "$branch"
}

greview() {
    local diff; diff=$(git diff --cached)
    [ -z "$diff" ] && { echo "❌ No staged changes."; return 1; }
    echo "$diff" | ginv "この Git 差分を日本語で短くコードレビューして。"
}

# --- 6. The Ultimate 'g' Function ---
unalias g 2>/dev/null
g() {
    if [ $# -gt 0 ]; then git "$@"; return; fi
    echo -e "\033[32m-- Branch Status --\033[0m"
    local br; br=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local up; up=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)
    if [ -n "$up" ]; then
        local c; c=$(git rev-list --left-right --count "$br"..."$up")
        # SC2086 対策: ダブルクォートで変数を囲む
        echo -e "* \033[33m$br\033[0m (Ahead: $(echo "$c" | awk '{print $1}'), Behind: $(echo "$c" | awk '{print $2}'))"
    else echo -e "* \033[33m$br\033[0m (No remote)"; fi
    echo -e "\n\033[36m-- Changes --\033[0m"
    git status --short | sed 's/^/  /'
    echo -e "\n\033[35m-- Recent Commits --\033[0m"
    git log -3 --pretty=format:"%C(yellow)%h%Creset %s"
    echo -e "\n"
}
