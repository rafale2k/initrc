#!/bin/bash
# ==========================================
# 共通設定: ナビゲーション (Navigation)
# ==========================================

# --- 1. ディレクトリ移動 ---
alias b='cd -'
alias mkdir='mkdir -p'
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# 昨日の up 関数をエイリアスでも活用
unalias up 2>/dev/null
up() {
    local d="" limit=$1
    if [ -z "$limit" ]; then cd ..; return; fi
    if [[ "$limit" =~ ^[0-9]+$ ]]; then
        for ((i=0; i < limit; i++)); do d="../$d"; done
        cd "$d" || return
    else
        local curr=$PWD
        while [[ "$curr" != "/" ]]; do
            curr=$(dirname "$curr")
            if [[ "$(basename "$curr")" == "$limit" ]]; then cd "$curr" || return; return; fi
        done
        echo "Directory '$limit' not found." && return 1
    fi
}
alias ..='up 1'
alias ...='up 2'
alias ....='up 3'

# --- 2. Smart History (今日の主役) ---
unalias h 2>/dev/null
h() {
    local selected
    # Monokaiカラーをベースにしたfzf履歴検索
    selected=$(history -n 1 | tac | fzf --height=40% \
        --prompt="History Search > " --query="$*" --reverse \
        --color="hl:148,hl+:148,info:141,prompt:141,pointer:197,marker:197" \
        --preview 'echo {} | fold -s -w $(($FZF_PREVIEW_COLUMNS - 2))' \
        --preview-window="up:3:hidden:wrap")

    if [ -n "$selected" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            print -z "$selected"
        else
            # bashの場合はクリップボードに入れて注意を促すか、そのまま入力
            echo "$selected" | clipcopy 2>/dev/null
            echo "Selected: $selected (Copied to clipboard)"
        fi
    fi
}

# --- 3. 検索 & 移動 (fe / fcd) ---
fe() {
    local file bat_cmd
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")
    file=$(find . -maxdepth 4 -not -path '*/.*' -o -path './.*' -not -name '.' 2> /dev/null | fzf \
        --preview "$bat_cmd --color=always --line-range :500 {}" \
        --preview-window=right:60% --height 80% --layout=reverse --border)
    if [[ -n "$file" ]]; then
        [ -d "$file" ] && cd "$file" || n "$file"
    fi
}

fcd() {
    local dir fd_cmd
    fd_cmd=$(command -v fdfind || command -v fd || echo "find")
    if command -v eza >/dev/null 2>&1; then
        dir=$($fd_cmd --type d --hidden --exclude .git . 2> /dev/null | \
            fzf --height 50% --reverse --border --preview 'eza -T -L 2 --icons --color=always {} | head -30')
    else
        dir=$($fd_cmd --type d --hidden --exclude .git . 2> /dev/null | fzf --height 40% --reverse --border)
    fi
    [ -n "$dir" ] && cd "$dir"
}

# --- 4. 外部ツール連携 (zoxide etc) ---
if command -v zoxide > /dev/null; then
    eval "$(zoxide init $([ -n "$ZSH_VERSION" ] && echo "zsh" || echo "bash"))"
    alias j='z'
    export _ZO_FZF_OPTS="--preview 'eza -T -L 2 --icons --color=always {2..}' --preview-window=right:50%"
fi
