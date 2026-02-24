#!/bin/bash
# --- Gemini AI Assistant: ask & wtf ---

ask() {
    local raw_prompt="$1"
    
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "❌ Error: GEMINI_API_KEY is not set in common/.env.local"
        return 1
    fi

    if [ -z "$raw_prompt" ]; then
        echo "🤔 Usage: ask \"Your question here\""
        return 1
    fi

    echo "🤖 Gemini is thinking..."

    local api_url="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}"

    # リクエストからパースまで、全てを Python 内部で完結させる。
    # シェルの変数展開や echo を一切介在させない。
    python3 -c '
import json, sys, urllib.request

prompt = sys.argv[1]
api_url = sys.argv[2]

data = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {"temperature": 0.7, "maxOutputTokens": 800}
}

try:
    req = urllib.request.Request(
        api_url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as res:
        response_body = res.read().decode("utf-8")
        result = json.loads(response_body)
        
        # JSONから回答テキストを抽出
        if "candidates" in result and result["candidates"]:
            text = result["candidates"][0]["content"]["parts"][0]["text"]
            print("\n--- 🤖 Gemini Response ---\n")
            print(text)
            print("\n--------------------------\n")
        else:
            print(f"❌ AI Response Error: {json.dumps(result)}")

except Exception as e:
    print(f"❌ Error: {str(e)}")
' "$raw_prompt" "$api_url"
}

wtf() {
    ask "私は今 Linux ターミナルで作業中ですが、直前のコマンドが失敗しました。原因と対策を簡潔に教えてください。"
}
