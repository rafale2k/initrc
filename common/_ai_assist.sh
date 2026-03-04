#!/bin/bash
# --- Gemini AI Assistant: ask, wtf, dask & dinv (llm powered v3.0) ---

# [本番級設定] 使用するモデルを一括管理
# 現時点で最も高性能な preview モデルを指定。安定版が良ければ gemini-2.5-flash に変更してください
export AI_ASSIST_MODEL="gemini/gemini-2.5-flash-preview"

# [内部用] 実行中のコンテナを fzf で選んで名前を返す関数
_select_container() {
    # 実行中のコンテナ一覧を取得し、右側にログを表示するプレビュー機能付き
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | \
        sed '1d' | \
        fzf --height 40% --layout=reverse --border \
            --header "Select a container to inspect (Preview shows last 20 lines of logs)" \
            --preview "docker logs --tail 20 {1} 2>&1" | \
        awk '{print $1}'
}

# [汎用] 質問からコマンドを生成・実行
ask() {
    local query="$*"
    [[ -z "$query" ]] && { echo "🤔 Usage: ask 'Your question'"; return 1; }

    # SC2155: Declare and assign separately to avoid masking return values.
    local system_prompt
    system_prompt="You are a pragmatic Shell Expert.
Output ONLY the executable shell command for $(uname) system.
- NO explanation.
- NO conversational text.
- NO markdown code blocks (\`\`\`).
- Ensure all quotes are properly balanced and escaped.
- Use one-liners only."

    echo "🤖 Thinking..."
    
    local model
    model="${AI_ASSIST_MODEL:-gemini-2.5-flash}"

    local raw_cmd
    # llmコマンドの失敗を検知できるように代入を分離
    raw_cmd=$(llm -m "$model" -s "$system_prompt" "$query") || { echo "❌ LLM execution failed."; return 1; }

    local cmd
    # SC2016: 以下の `sed` 内の `\` はリテラルとして扱うため、警告を無効化するか
    # または正規表現として正しく解釈されるよう記述を維持。
    # ここではShellcheckに意図的であることを伝える注釈を入れるか、クォートを微調整。
    # shellcheck disable=SC2016
    cmd=$(echo "$raw_cmd" | sed -E 's/^`{1,3}([a-z]*)?//g; s/`{1,3}$//g' | xargs)

    [[ -z "$cmd" ]] && { echo "❌ Failed to generate command."; return 1; }

    echo -e "\n👉 AI suggests:\n\033[1;32m$cmd\033[0m\n"
    
    echo -n "Run this command? [y/N]: "
    local answer
    # read の際、標準入力がパイプ等の場合を考慮して /dev/tty から直接読み込む
    read -r answer < /dev/tty

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "🚀 Executing..."
        # eval で実行。historyに載せたい場合は別の工夫が必要だが、基本はこれで動作する。
        eval "$cmd"
    else
        echo "Aborted."
    fi
}

# [Docker特化] コンテキストを読み取って操作を提案
dask() {
    local query="$*"
    [[ -z "$query" ]] && { echo "🤔 Usage: dask 'Docker task'"; return 1; }

    echo "🐳 Analyzing Docker context..."

    # 賢さを最大化するためのコンテキスト収集
    local context="[Context]\n"
    [[ -f "docker-compose.yml" ]] && context+="Compose File (head):\n$(head -n 50 docker-compose.yml)\n\n"
    context+="Container Status:\n$(docker ps --format '{{.Names}} ({{.Status}})')\n"
    # 直近のエラーログを含めることで、トラブル解決の精度を劇的に上げる
    context+="Recent Logs excerpt:\n$(docker compose logs --tail 15 2>/dev/null)\n"

    local system_prompt="You are a Docker/DevOps expert. 
    1. Output a brief explanation (1 line) about why this command is suggested.
    2. Output the command in a NEW line.
    3. Use NO markdown formatting."

    local response
    response=$(echo -e "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query")

    # 1行目の解説と2行目以降のコマンドを分離
    local explanation cmd
    explanation=$(echo "$response" | head -n 1)
    cmd=$(echo "$response" | tail -n +2 | xargs)

    [[ -z "$cmd" ]] && { echo "❌ Failed to generate command."; return 1; }

    echo -e "\n💡 \033[1;34m$explanation\033[0m"
    echo -e "👉 AI suggests: \033[1;32m$cmd\033[0m\n"
    
    echo -n "Run? [y/N]: "
    local answer
    read -r answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "🚀 Executing..."
        ( /bin/bash -c "$cmd" )
    fi
}

# [解析] ログやエラーメッセージの解決策を提示
wtf() {
    local context
    if [[ -n "$1" ]]; then
        context="$1"
    else
        context=$(clipcopy --paste 2>/dev/null || pbpaste 2>/dev/null)
    fi
    
    [[ -z "$context" ]] && { echo "⚠️ No error context found in arguments or clipboard."; return 1; }

    echo "🔍 Analyzing error..."
    local system_prompt="You are a senior DevOps engineer. Analyze this error and provide a concise fix."
    
    echo -e "--- 🤖 Error Analysis ---\n"
    # glow があれば綺麗に表示
    if command -v glow > /dev/null; then
        echo "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" | glow
    else
        echo "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt"
    fi
    echo -e "\n--------------------------"
}

# [調査] コンテナ内のファイルを SRE 視点で精密診断
dinv() {
    local container=$1
    local file_path=$2
    local query=${3:-"Analyze this file for any misconfigurations, security risks, or performance issues. Provide a 'Summary' and 'Action Plan'."}

    # コンテナ名がなければ fzf で選択
    if [[ -z "$container" ]]; then
        container=$(_select_container)
        [[ -z "$container" ]] && return 1
        echo "✅ Selected: $container"
    fi

    # ファイルパスがなければ入力を促す
    if [[ -z "$file_path" ]]; then
        echo -n "Enter file path to inspect (e.g. /etc/mysql/my.cnf): "
        read -r file_path < /dev/tty
        [[ -z "$file_path" ]] && return 1
    fi

    echo "🔍 Reading $file_path from $container..."
    local content
    content=$(docker exec "$container" cat "$file_path" 2>/dev/null)
    
    if [[ -z "$content" ]]; then
        echo "❌ File not found or empty."
        return 1
    fi

    local system_prompt="You are a Senior SRE specialist. Address the query based on the file content provided."
    
    echo -e "🤖 Analyzing with Gemini...\n"
    if command -v glow > /dev/null; then
        echo -e "[File: $file_path]\n$content" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query" | glow
    else
        echo -e "[File: $file_path]\n$content" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query"
    fi
}
