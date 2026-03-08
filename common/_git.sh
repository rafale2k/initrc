#!/bin/bash

# --- 1. Git Basic Aliases ---
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
alias gundo='git reset --soft HEAD~1'
alias gfix='git commit --amend --no-edit'
unalias gl 2>/dev/null 
alias gl='git log --oneline --graph --decorate'
alias gnw='git diff -w --no-ext-diff'

# --- 2. Git Main Branch Sync (Enhanced) ---
# stash を挟んで安全にメインブランチへ戻り、最新を取り込む
alias gms='git stash && git checkout $(git symbolic-ref --short refs/remotes/origin/HEAD | sed "s/origin\///") && git pull && git stash pop 2>/dev/null || true'

# --- 3. git-extras Power Aliases ---
alias gsum='git summary'     # プロジェクト概要
gtoday() { git standup "$@"; } # 直近24時間の活動 (引数対応)
alias gcount='git effort --above 5' # 修正回数ランキング
alias gline='git line'       # 1行ログ (作者名/相対時間入り)
alias ggraph='git graph'     # 綺麗なグラフ表示

# --- 4. Cleanup (Local & Remote) ---
# ローカルのマージ済みブランチ削除
alias gcl='git branch --merged | grep -vE "^\*|master|main|develop" | xargs -r git branch -d'
# リモートのマージ済みブランチを一括削除 (origin)
alias gclr='git branch -r --merged | grep -vE "master|main|develop|HEAD" | sed "s/origin\///" | xargs -I% git push origin --delete %'

# --- 5. Clipboard Utility (gcp-hash) ---
gcp-hash() {
    local hash
    hash=$(git rev-parse HEAD)
    if command -v clipcopy &> /dev/null; then
        echo -n "$hash" | clipcopy
        echo "📋 Hash $hash copied to clipboard (via clipcopy)."
    elif command -v pbcopy &> /dev/null; then
        echo -n "$hash" | pbcopy
        echo "📋 Hash $hash copied to clipboard (via pbcopy)."
    else
        echo "❌ Clipboard tool not found. Hash: $hash"
    fi
}

# --- 6. Functions ---
gquick() {
    local msg=$1
    if [ -z "$msg" ]; then
        msg="Quick sync: $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    echo "🚀 Starting quick sync..."
    git add -A
    git commit -m "$msg"
    local branch
    branch=$(git symbolic-ref --short HEAD)
    git push origin "$branch"
    echo "✨ Done! Pushed to $branch."
}

# --- 7. AI Support (aic / greview) ---
if [ -f "$DOTFILES_PATH/bin/aic" ]; then
    alias aic='$DOTFILES_PATH/bin/aic'
fi

# ステージングされた差分を AI にレビューさせる
greview() {
    local diff=$(git diff --cached)
    if [ -z "$diff" ]; then
        echo "❌ No staged changes to review."
        return 1
    fi
    echo "$diff" | ginv "この Git 差分のコードレビューをして。バグの可能性や改善点があれば指摘して。日本語で短く頼むわ。"
}

# --- 8. The Ultimate 'g' Function ---
unalias g 2>/dev/null
g() {
    if [ $# -gt 0 ]; then
        git "$@"
        return
    fi

    # 1. Branch & Remote Sync Status (Ahead/Behind 可視化)
    echo -e "\033[32m-- Branch Status --\033[0m"
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ -z "$branch" ] && return
    
    local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [ -n "$upstream" ]; then
        local counts=$(git rev-list --left-right --count $branch...$upstream)
        local ahead=$(echo $counts | awk '{print $1}')
        local behind=$(echo $counts | awk '{print $2}')
        echo -ne "* \033[33m$branch\033[0m (Ahead: $ahead, Behind: $behind)\n"
    else
        echo -e "* \033[33m$branch\033[0m (No remote tracking)"
    fi

    # 2. Short Status
    echo -e "\n\033[36m-- Changes --\033[0m"
    if [ -z "$(git status --short)" ]; then
        echo "  Clean (nothing to commit)"
    else
        git status --short | sed 's/^/  /'
    fi

    # 3. Recent 3 Commits
    echo -e "\n\033[35m-- Recent Commits --\033[0m"
    git log -3 --pretty=format:"%C(yellow)%h%Creset %C(magenta)%ad%Creset %s %C(cyan)(%an)%Creset" --date=short
    echo -e "\n"
}
