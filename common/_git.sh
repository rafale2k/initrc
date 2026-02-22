#!/bin/bash
unalias gcm 2>/dev/null

# --- AI Commit Message Generator (Quality Focused) ---
_ai_generate_commit_message() {
    [[ -z "$GEMINI_API_KEY" ]] && return 1

    local diff_content
    diff_content=$(git diff --cached | head -c 5000)
    [[ -z "$diff_content" ]] && return 1

    export RAW_DIFF_CONTENT="$diff_content"
    export GEMINI_API_KEY_ENV="$GEMINI_API_KEY"

    local message
    message=$(python3 <<'EOF'
import json
import urllib.request
import os

def solve():
    api_key = os.environ.get("GEMINI_API_KEY_ENV")
    diff_text = os.environ.get("RAW_DIFF_CONTENT", "")
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    
    # 英語での要約指示（品質を上げるため、思考の余地を与える）
    system_prompt = (
        "You are an expert software engineer. Analyze the provided git diff and "
        "write a concise, high-quality commit message in English. "
        "Use Conventional Commits format (feat:, fix:, chore:, etc.). "
        "Focus on 'why' and 'what' changed. Keep it under 72 characters."
    )
    
    user_prompt = f"Summarize this diff into a single line commit message:\n\n{diff_text}"

    data = {
        "system_instruction": {"parts": [{"text": system_prompt}]},
        "contents": [{"parts": [{"text": user_prompt}]}]
    }

    req = urllib.request.Request(
        url, 
        data=json.dumps(data).encode("utf-8"), 
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            resp = json.loads(res.read().decode("utf-8"))
            return resp["candidates"][0]["content"]["parts"][0]["text"].strip()
    except:
        return None

print(solve() or "")
EOF
)

    unset RAW_DIFF_CONTENT
    unset GEMINI_API_KEY_ENV

    [[ -z "$message" || "$message" == "null" ]] && return 1
    
    # 記号のクリーニング
    echo "$message" | sed 's/^`//g; s/`$//g' | xargs
}

# --- Enhanced Git Commit (gcm) ---
gcm() {
    if [ -z "$(git diff --cached)" ]; then
        echo "❌ No changes staged."
        return 1
    fi

    echo "🤖 AI is summarizing (Quality Mode)..."
    
    local ai_message
    ai_message=$(_ai_generate_commit_message)

    local -a choices
    choices=()
    [[ -n "$ai_message" ]] && choices+=("$ai_message")
    choices+=("feat: update configuration" "fix: minor bug fixes" "docs: update documentation" "[Manual Input]")

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

    [[ -n "$selected" ]] && git commit -m "$selected"
}
