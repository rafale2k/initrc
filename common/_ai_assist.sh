#!/bin/bash
# --- Gemini AI Assistant: ask & wtf (llm powered) ---

ask() {
    local query="$*"
    if [[ -z "$query" ]]; then
        echo "🤔 Usage: ask 'Your question here'"
        return 1
    fi

    echo "🤖 Thinking (Gemini via llm)..."
    
    # llm をバックエンドに使用。システムプロンプトで「簡潔な回答」を指示
    llm -m gemini-2.5-flash -s "You are a helpful CLI assistant. Keep answers concise and practical." "$query"
}

wtf() {
    echo "🔍 Analyzing the situation..."

    # 1. 直前のエラー出力を取得する工夫
    # クリップボードにある内容、または引数で渡されたエラー文を優先
    local context
    if [[ -n "$1" ]]; then
        context="$1"
    else
        # clipcopy (--paste) または pbpaste から取得を試みる
        context=$(clipcopy --paste 2>/dev/null || pbpaste 2>/dev/null)
    fi

    if [[ -z "$context" ]]; then
        echo "⚠️  Error context not found. Please copy the error message to clipboard and run 'wtf' again."
        return 1
    fi

    # 2. AI にコンテキストを渡して解析
    local system_prompt="You are a senior DevOps engineer. 
Analyze this CLI error and explain:
1. What went wrong?
2. How to fix it (provide specific commands).
Keep it very concise."

    echo -e "--- 🤖 Error Analysis ---\n"
    echo "$context" | llm -m gemini-2.5-flash -s "$system_prompt"
    echo -e "\n--------------------------"
}
