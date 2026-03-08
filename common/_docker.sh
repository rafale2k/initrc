#!/bin/bash
# ------------------------------------------------------------------------------
# common/_docker.sh: Docker ワークフロー最適化 (v2.0.0)
# ------------------------------------------------------------------------------

# Docker API バージョンと警告抑制
export DOCKER_API_VERSION=1.53
export DOCKER_HIDE_LEGACY_VERSION_WARNING=true

# --- 1. 基本エイリアス ---
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcub='docker compose up -d --build'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dclt='docker compose logs -f --tail 50'

# --- 2. 視認性向上 & 調査 ---
# [dps] 起動状態を色付けし、ポートも見やすく
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -e "s/Up/$(printf "\033[32mUp\033[0m")/g" -e "s/Exited/$(printf "\033[31mExited\033[0m")/g"'

# [dip] コンテナの内部 IP アドレスを一瞬で表示
alias dip="docker ps -q | xargs -n 1 docker inspect --format '{{ .Name }}: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | sed 's/\///'"

# [dim] イメージをサイズ順に並べて表示（肥大化チェック）
alias dim='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | (read -r; printf "%s\n" "$REPLY"; sort -hr -k3)'

# --- 3. メンテナンス (掃除) ---
# 停止中のコンテナ、未使用ネットワーク、ダングリングイメージを削除
alias dclean='docker system prune -f'
# ボリュームも含む、未使用リソースをすべて強制削除
alias dclean-all='docker system prune -a --volumes -f'

# --- 4. インタラクティブ関数 (fzf 連携) ---

# [de] コンテナを選択して Exec
de() {
    local container="$1"
    if [ -z "$container" ] && command -v fzf &> /dev/null; then
        container=$(docker ps --format "{{.Names}}" | fzf --prompt="🐳 Select Container (Exec) > " --height 40% --reverse)
    fi
    [ -z "$container" ] && return
    
    # ユーザー指定がなければ root を試みるが、環境に合わせて調整
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

# [drm] コンテナを選択して停止・削除 (複数選択可)
unalias drm 2>/dev/null
drm() {
    local containers
    if command -v fzf &> /dev/null; then
        containers=$(docker ps -a --format "{{.Names}}" | fzf --multi --prompt="🗑️ Select Containers to Remove (TAB to multi-select) > " --height 40% --reverse)
        if [ -n "$containers" ]; then
            echo "$containers" | xargs -I {} sh -c "docker stop {} && docker rm {}"
        fi
    else
        echo "⚠️ fzf is required for drm."
    fi
}

# [dri] 未使用イメージを選択して削除
dri() {
    local images
    if command -v fzf &> /dev/null; then
        images=$(docker images --format "{{.Repository}}:{{.Tag}} ({{.ID}})" | fzf --multi --prompt="🖼️ Select Images to Remove > " --height 40% --reverse | awk -F'(' '{print $2}' | tr -d ')')
        if [ -n "$images" ]; then
            echo "$images" | xargs docker rmi
        fi
    fi
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
