#!/bin/bash
# Git エイリアス & 関数
unalias gcm 2>/dev/null

alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push origin main'
alias gl='git lg'

# --- AI Commit Message Generator ---
_ai_generate_commit_message() {
    [[ -z "$GEMINI_API_KEY" ]] && return 1

    # diffを取得（制御文字が含まれる可能性を考慮）
    local diff_text
    diff_text=$(git diff --cached | head -c 4000)
    [[ -z "$diff_text" ]] && return 1

    # プロンプト構成：日本語を最優先に指示
    local raw_prompt="【指示】日本語で出力せよ。
git diffから、Conventional Commits形式のコミットメッセージを1行だけ作成してください。
思考プロセスや解説は一切不要。出力は日本語のメッセージ1行のみとすること。
diff:
$diff_text"

    # 制御文字によるJSONパースエラーを防ぐため、--arg で確実にエスケープ
    local json_data
    json_data=$(jq -n --arg msg "$raw_prompt" '{"contents": [{"parts": [{"text": $msg}]}]}')

    # モデルは爆速の 2.0-flash-lite
    local response
    response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${GEMINI_API_KEY}" \
        -H 'Content-Type: application/json' \
        -d "$json_data")

    # 再帰探索で確実にメッセージを抽出
    local message
    message=$(echo "$response" | jq -r '.. | .text? // empty' | grep -v "null" | head -n 1 | sed 's/^`//g; s/`$//g' | xargs)

    [[ -z "$message" || "$message" == "null" ]] && return 1
    echo "$message"
}

# --- Enhanced Git Commit (gcm) ---
gcm() {
    if [ -z "$(git diff --cached)" ]; then
        echo "No changes staged."
        return 1
    fi

    echo "🤖 AI is thinking (Fast Mode)..."
    
    local ai_message
    ai_message=$(_ai_generate_commit_message)

    local -a choices
    choices=()
    # AIが成功した時だけ選択肢の先頭に追加
    if [[ -n "$ai_message" ]]; then
        choices+=("$ai_message")
    fi
    
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
