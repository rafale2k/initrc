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
alias dip="docker ps -q | xargs docker inspect --format '{{ .Name }}: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | sed 's/\///'"

# [dim] イメージをサイズ順に並べて表示（肥大化チェック）
alias dim='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | (read -r; printf "%s\n" "$REPLY"; sort -hr -k3)'

# [dhist] 特定のイメージのレイヤーごとのサイズと作成コマンドを表示
alias dhist='docker history --human --format "table {{.ID}}\t{{.CreatedBy}}\t{{.Size}}"'

# --- 3. メンテナンス (掃除) ---
# 停止中のコンテナ、未使用ネットワーク、ダングリングイメージを削除
alias dclean='docker system prune -f'
# ボリュームも含む、未使用リソースをすべて強制削除
alias dclean-all='docker system prune -a --volumes -f'


# --- 4. インタラクティブ関数 (fzf 連携) ---

# [helper] fzf 共通ラッパー
_docker_fzf_select() {
    local prompt="$1"
    shift
    if ! command -v fzf &> /dev/null; then
        echo "⚠️ fzf is required for this command." >&2
        return 1
    fi
    fzf --prompt="$prompt" --height 40% --reverse "$@"
}

# [de] コンテナを選択して Exec
de() {
    local container="$1"
    if [ -z "$container" ]; then
        container=$(docker ps --format "{{.Names}}" | _docker_fzf_select "🐳 Select Container (Exec) > ")
    fi
    [ -z "$container" ] && return 0

    # ユーザー指定がなければ root を試みるが、環境に合わせて調整
    docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
}

# [dl] コンテナを選択して Logs 表示
dl() {
    local container="$1"
    if [ -z "$container" ]; then
        container=$(docker ps -a --format "{{.Names}}" | _docker_fzf_select "📜 Select Container (Logs) > ")
    fi
    [ -z "$container" ] && return 0

    docker logs -f --tail 100 "$container"
}

# [drm] コンテナを選択して停止・削除 (複数選択可)
unalias drm 2>/dev/null || true
drm() {
    local containers
    containers=$(docker ps -a --format "{{.Names}}" | _docker_fzf_select "🗑️ Select Containers to Remove (TAB to multi-select) > " --multi)
    if [ -n "$containers" ]; then
        echo "$containers" | xargs docker stop
        echo "$containers" | xargs docker rm
    fi
}

# [dri] 未使用イメージを選択して削除
dri() {
    local images
    images=$(docker images --format "{{.Repository}}:{{.Tag}} ({{.ID}})" | _docker_fzf_select "🖼️ Select Images to Remove > " --multi | awk -F'(' '{print $2}' | tr -d ')')
    if [ -n "$images" ]; then
        echo "$images" | xargs docker rmi
    fi
}

# [dce] Compose サービスを選択して Exec
unalias dce 2>/dev/null || true
dce() {
    local service
    service=$(docker compose ps --services | _docker_fzf_select "🚀 Select Service (Compose Exec) > ")
    [ -z "$service" ] && return 0

    docker compose exec "$service" /bin/bash || docker compose exec "$service" /bin/sh
}
