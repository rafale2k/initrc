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

# --- AI Commit Message Generator (Gemini 2.0 Flash Lite for Speed) ---
_ai_generate_commit_message() {
    [[ -z "$GEMINI_API_KEY" ]] && return 1

    local diff_text=$(git diff --cached | head -c 4000)
    [[ -z "$diff_text" ]] && return 1

    # 思考をスキップさせる超速プロンプト
    local raw_prompt="git diffから1行のコミットメッセージのみ作成して。思考不要、解説不要、出力はメッセージ1行のみ。日本語。Conventional Commits形式で。\ndiff:\n$diff_text"
    local json_data=$(jq -n --arg msg "$raw_prompt" '{contents: [{parts: [{text: $msg}]}]}')

    # モデルを 2.0-flash-lite に変更（爆速）
    local response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${GEMINI_API_KEY}" \
        -H 'Content-Type: application/json' \
        -d "$json_data")

    # 抽出処理
    local message=$(echo "$response" | jq -r '.. | .text? // empty' | grep -v "null" | head -n 1 | sed 's/^`//g; s/`$//g' | xargs)

    [[ -z "$message" || "$message" == "null" ]] && return 1
    echo "$message"
}

# --- Enhanced Git Commit (gcm) ---
gcm() {
    if [ -z "$(git diff --cached)" ]; then
        echo "No changes staged. Use 'ga' or 'gaa' first."
        return 1
    fi

    echo "🤖 AI is thinking (Speed mode)..."
    
    local ai_message
    ai_message=$(_ai_generate_commit_message)

    # 配列の初期化をより確実に
    local -a choices
    choices=()
    [[ -n "$ai_message" ]] && choices+=("$ai_message")
    choices+=("feat: update configuration")
    choices+=("fix: minor bug fixes")
    choices+=("docs: update documentation")
    choices+=("[Manual Input]")

    local selected
    selected=$(printf "%s\n" "${choices[@]}" | fzf --height 40% --reverse --border --header "Select commit message")

    if [[ -z "$selected" ]]; then
        echo "Commit cancelled."
        return 1
    fi

    if [[ "$selected" == "[Manual Input]" ]]; then
        echo -n "Enter commit message: "
        read manual_message
        selected=$manual_message
    fi

    if [[ -n "$selected" ]]; then
        git commit -m "$selected"
    else
        echo "Commit cancelled: Empty message."
        return 1
    fi
}

alias gca='git commit --amend'
gls() { git log --oneline --graph --all -i --grep="$1"; }
