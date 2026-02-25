#!/bin/bash
# ------------------------------------------------------------------------------
# common/_docker.sh: Docker ワークフロー最適化 (fzf 連携 & メンテナンス)
# ------------------------------------------------------------------------------

# Docker API バージョンと警告抑制
export DOCKER_API_VERSION=1.53
export DOCKER_HIDE_LEGACY_VERSION_WARNING=true

# --- 基本エイリアス ---
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcub='docker compose up -d --build'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'

# --- 視認性向上 ---
# 起動状態 (Up) を緑色でハイライト
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -e "s/Up/$(printf "\033[32mUp\033[0m")/g"'

# --- メンテナンス (掃除) ---
# 停止中のコンテナ、未使用のネットワーク、ダングリングイメージを削除
alias dclean='docker system prune -f'

# ボリュームも含む、未使用リソースをすべて強制削除
alias dclean-all='docker system prune -a --volumes -f'

# --- インタラクティブ関数 (fzf) ---

# [de] コンテナを選択して Exec
de() {
    local container="$1"
    if [ -z "$container" ] && command -v fzf &> /dev/null; then
        container=$(docker ps --format "{{.Names}}" | fzf --prompt="🐳 Select Container (Exec) > " --height 40% --reverse)
    fi
    [ -z "$container" ] && return
    
    # bash がなければ sh で試行
    docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
}

# [dl] コンテナを選択して Logs 表示
dl() {
    local container="$1"
    if [ -z "$container" ] && command -v fzf &> /dev/null; then
        container=$(docker ps -a --format "{{.Names}}" | fzf --prompt="📜 Select Container (Logs) > " --height 40% --reverse)
    fi
    [ -z "$container" ] && return
    
    docker logs -f --tail 100 "$container"
}

# [dce] Compose サービスを選択して Exec
unalias dce 2>/dev/null
dce() {
    local service
    if ! command -v fzf &> /dev/null; then
        echo "⚠️ fzf is not installed."
        return 1
    fi
    
    service=$(docker compose ps --services | fzf --prompt="🚀 Select Service (Compose Exec) > " --height 40% --reverse)
    [ -z "$service" ] && return
    
    docker compose exec "$service" /bin/bash || docker compose exec "$service" /bin/sh
}

# --- 完了通知 ---
# 読み込み確認用（デバッグ時以外はコメントアウト可）
# echo "✅ Docker helper v1.9.0 loaded."
