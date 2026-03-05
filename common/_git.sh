#!/bin/bash

# --- Git Basic Aliases ---
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
unalias gl 2>/dev/null 
alias gl='git log --oneline --graph --decorate'
alias gnw='git diff -w --no-ext-diff'

# --- Git Main Branch Sync ---
# デフォルトブランチを自動取得して pull
alias gms='git checkout $(git symbolic-ref --short refs/remotes/origin/HEAD | sed "s/origin\///") && git pull'

# --- git-extras Power Aliases ---
# プロジェクトの概要（作者、コミット数、最新の変更等）を一瞬で表示
alias gsum='git summary'

# 直近 24 時間の活動をサクッと確認
alias gtoday='git standup'

# 誰が一番コードを書いてるか（貢献度）をランキング表示
alias gcount='git effort --above 5'

# ログをより見やすく（作者名、相対時間入り）
alias gline='git line'

# ブランチのグラフ表示をさらに綺麗に（git-extrasのグラフィカルログ）
alias ggraph='git graph'

# --- Clipboard Utility (OSC 52 / pbcopy 兼用) ---
# 直近のコミットハッシュをクリップボードへ
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

# --- Functions ---
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

# ---  aic (Git Commit Message AI) ---
if [ -f "$DOTFILES_PATH/bin/aic" ]; then
    alias aic='$DOTFILES_PATH/bin/aic'
fi

unalias g 2>/dev/null
g() {
    # 引数があればそのまま git に渡す (g commit -m ... とか)
    if [ $# -gt 0 ]; then
        git "$@"
        return
    fi

    # 1. ブランチ情報と同期状態 (Monokai Green/Pink)
    echo -e "\033[32m-- Branch Status --\033[0m"
    command git branch -vv | grep "^\*" | sed "s/^\* //"
    
    # 2. 短縮版ステータス (Monokai Blue)
    echo -e "\n\033[36m-- Changes --\033[0m"
    if [ -z "$(git status --short)" ]; then
        echo "  Clean (nothing to commit)"
    else
        git status --short
    fi

    # 3. 直近 3 つのコミット (Monokai Purple/Gray)
    echo -e "\n\033[35m-- Recent Commits --\033[0m"
    git log -3 --pretty=format:"%C(yellow)%h%Creset %C(magenta)%ad%Creset %s %C(cyan)(%an)%Creset" --date=short
    echo ""
}
