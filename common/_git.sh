#!/bin/bash
unalias gcm 2>/dev/null

# --- AI Commit Message Generator (Stable & Multi-Proposal) ---
_ai_generate_commit_proposals() {
    [[ -z "$GEMINI_API_KEY" ]] && return 1

    # diffをBase64化して特殊文字の影響をゼロにする
    local diff_b64
    diff_b64=$(git diff --cached | head -c 10000 | base64 | tr -d '\n')
    [[ -z "$diff_b64" ]] && return 1
    
    export DIFF_B64_DATA="$diff_b64"
    export GEMINI_API_KEY_ENV="$GEMINI_API_KEY"

    # Pythonブリッジ
    python3 <<'EOF'
import json
import urllib.request
import os

def fetch():
    key = os.environ.get("GEMINI_API_KEY_ENV")
    b64_diff = os.environ.get("DIFF_B64_DATA", "")
    
    # 制限が厳しい2.0を避け、安定している 1.5-flash をメインに据える
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={key}"
    
    sys_inst = (
        "You are an expert developer. The input is a Base64 encoded git diff. "
        "Decode it and provide 3 high-quality commit messages in English. "
        "Format: Conventional Commits. Output ONLY 3 lines of messages. No numbers."
    )
    
    payload = {
        "system_instruction": {"parts": [{"text": sys_inst}]},
        "contents": [{"parts": [{"text": f"Base64 Diff:\n{b64_diff}"}]}]
    }

    try:
        req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as res:
            data = json.loads(res.read().decode("utf-8"))
            text = data['candidates'][0]['content']['parts'][0]['text']
            # 行をクリーンにして出力
            lines = [l.strip().lstrip('1234567890.+-* ').strip('` ') for l in text.strip().split('\n') if l.strip()]
            for l in lines[:3]: print(l)
    except:
        pass

fetch()
EOF
    unset DIFF_B64_DATA
    unset GEMINI_API_KEY_ENV
}

# --- gcm (Git Commit AI Selector) ---
gcm() {
    if [ -z "$(git diff --cached)" ]; then
        echo "❌ No changes staged."
        return 1
    fi

    echo "🤖 AI is thinking (Gemini 1.5 Flash Mode)..."
    
    local proposals
    proposals=$(_ai_generate_commit_proposals)

    local -a choices
    choices=()
    if [[ -n "$proposals" ]]; then
        while IFS= read -r line; do
            choices+=("$line")
        done <<< "$proposals"
        choices+=("---")
    else
        echo "⚠️ API still on cool-down. Try again in a minute."
    fi

    choices+=("feat: update configuration" "fix: minor bug fixes" "[Manual Input]")

    local selected
    selected=$(printf "%s\n" "${choices[@]}" | fzf --height 60% --reverse --border --header "Select AI proposal")

    [[ -z "$selected" || "$selected" == "---" ]] && { echo "Cancelled."; return 1; }

    if [[ "$selected" == "[Manual Input]" ]]; then
        echo -n "Enter message: "
        read manual_message
        selected=$manual_message
    fi

    [[ -n "$selected" ]] && git commit -m "$selected"
}
