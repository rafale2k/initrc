#!/bin/bash
# shellcheck shell=bash
# --- Gemini AI Assistant: ask, wtf, dask, kask & dinv (llm powered v3.1) ---

# [本番級設定] 使用するモデルを一括管理
export AI_ASSIST_MODEL="gemini/gemini-3-flash-preview"

# --- 内部ユーティリティ ---

# 実行中のコンテナを fzf で選ぶ
_select_container() {
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | \
        sed '1d' | \
        fzf --height 40% --layout=reverse --border \
            --header "Select a container (Preview shows logs)" \
            --preview "docker logs --tail 20 {1} 2>&1" | \
        awk '{print $1}'
}

# 生成されたコマンドの安全性をチェック
_is_safe_command() {
    local cmd="$1"
    # 破壊的なコマンドのパターンを検知
    if [[ "$cmd" =~ rm[[:space:]]+-rf[[:space:]]+(/|\$HOME|/[a-zA-Z0-9]+[[:space:]]*$) ]]; then
        return 1
    fi
    return 0
}

# AI提案のコマンドを実行するか確認して実行
_execute_ai_cmd() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { echo "❌ No command generated."; return 1; }

    if ! _is_safe_command "$cmd"; then
        echo -e "\n⚠️  \033[1;31mDangerous command detected!\033[0m: $cmd"
        echo "Execution blocked for safety."
        return 1
    fi

    echo -e "\n👉 AI suggests: \033[1;32m$cmd\033[0m\n"
    echo -n "Run this command? [y/N]: "
    local answer
    read -r answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "🚀 Executing..."
        eval "$cmd"
    else
        echo "Aborted."
    fi
}

# 出力をフォーマット表示する内部関数 (SC2015 対策)
_display_output() {
    if command -v glow >/dev/null 2>&1; then
        glow
    else
        cat
    fi
}

# --- メイン関数 ---

# [汎用] 質問からコマンドを生成
ask() {
    local query="$*"
    [[ -z "$query" ]] && { echo "🤔 Usage: ask 'Your question'"; return 1; }

    # SC2155 対策: 宣言と代入を分ける
    local system_prompt
    system_prompt="You are a pragmatic Shell Expert. Output ONLY the executable shell command for $(uname). No markdown, no explanation, no code blocks."
    
    echo "🤖 Thinking..."
    
    local raw_cmd
    raw_cmd=$(llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query") || return 1
    
    local cmd
    # shellcheck disable=SC2016
    cmd=$(echo "$raw_cmd" | sed -E 's/^`{1,3}([a-z]*)?//g; s/`{1,3}$//g' | xargs)
    
    _execute_ai_cmd "$cmd"
}

# [Docker特化] コンテキストを読み取って操作を提案
dask() {
    local query="$*"
    [[ -z "$query" ]] && { echo "🤔 Usage: dask 'Docker task'"; return 1; }

    echo "🐳 Analyzing Docker context..."
    local context="[Context]\n"
    [[ -f "docker-compose.yml" ]] && context+="Compose File (head):\n$(head -n 50 docker-compose.yml)\n\n"
    context+="Container Status:\n$(docker ps --format '{{.Names}} ({{.Status}})')\n"
    context+="Recent Logs excerpt:\n$(docker compose logs --tail 15 2>/dev/null)\n"

    local system_prompt="You are a Docker expert. 1. Brief explanation (1 line). 2. Command in new line. No markdown."
    local response
    response=$(echo -e "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query")

    local explanation cmd
    explanation=$(echo "$response" | head -n 1)
    cmd=$(echo "$response" | tail -n +2 | xargs)

    echo -e "\n💡 \033[1;34m$explanation\033[0m"
    _execute_ai_cmd "$cmd"
}

# [K8s特化] クラスターの状態を読み取って提案
kask() {
    if ! command -v kubectl &> /dev/null; then echo "❌ kubectl not found"; return 1; fi
    local query="$*"
    [[ -z "$query" ]] && { echo "🤔 Usage: kask 'K8s task'"; return 1; }

    echo "☸️  Gathering Cluster Context..."
    local ns
    ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")
    
    local context="[K8s Context]\nNamespace: $ns\n"
    context+="Events (Errors):\n$(kubectl get events --sort-by='.lastTimestamp' | grep -iE "error|fail|warn" | tail -n 5)\n"
    context+="Pod Status:\n$(kubectl get pods --field-selector status.phase!=Running)\n"

    local system_prompt="You are a Kubernetes/SRE expert. 1. Brief explanation. 2. Command in new line. No markdown."
    local response
    response=$(echo -e "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query")
    
    local explanation cmd
    explanation=$(echo "$response" | head -n 1)
    cmd=$(echo "$response" | tail -n +2 | xargs)

    echo -e "\n💡 \033[1;34m$explanation\033[0m"
    _execute_ai_cmd "$cmd"
}

# [解析] ログやエラーメッセージの解決策
wtf() {
    local context="$*"
    if [[ -z "$context" ]]; then
        context=$(clipcopy --paste 2>/dev/null || pbpaste 2>/dev/null)
        [[ -z "$context" ]] && context="Last command context: $(fc -ln -1)"
    fi
    
    echo "🔍 Analyzing error..."
    local system_prompt="You are a senior DevOps engineer. Analyze this error and provide a concise fix in markdown."
    echo -e "--- 🤖 Error Analysis ---\n"
    # SC2015 対策: パイプ先を専用の関数へ
    echo "$context" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" | _display_output
    echo -e "\n--------------------------"
}

# [調査] コンテナ内のファイルをSRE視点で診断
dinv() {
    local container=$1
    local file_path=$2
    local query=${3:-"Analyze this file for any misconfigurations, security risks, or performance issues."}

    [[ -z "$container" ]] && { container=$(_select_container); [[ -z "$container" ]] && return 1; }
    if [[ -z "$file_path" ]]; then
        echo -n "Enter file path to inspect: "
        read -r file_path < /dev/tty
        [[ -z "$file_path" ]] && return 1
    fi

    echo "🔍 Reading $file_path from $container..."
    local content
    content=$(docker exec "$container" cat "$file_path" 2>/dev/null)
    
    [[ -z "$content" ]] && { echo "❌ File not found or empty."; return 1; }

    local system_prompt="You are a Senior SRE. Analyze the provided file content based on the query."
    echo -e "🤖 Analyzing with Gemini...\n"
    # SC2015 対策
    echo -e "[File: $file_path]\n$content" | llm -m "$AI_ASSIST_MODEL" -s "$system_prompt" "$query" | _display_output
}

alias lz='"$DOTPATH"/scripts/log_wizard.py'
