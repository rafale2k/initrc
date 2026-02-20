#!/bin/bash
export DOCKER_API_VERSION=1.53
export DOCKER_HIDE_LEGACY_VERSION_WARNING=true

alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -e "s/Up/$(printf "\033[32mUp\033[0m")/g"'

de() {
    local container="$1"
    if [ -z "$container" ] && command -v fzf &> /dev/null; then
        container=$(docker ps --format "{{.Names}}" | fzf --prompt="Select Container (Exec) > ")
    fi
    [ -z "$container" ] && return
    docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
}

dl() {
    local container="$1"
    if [ -z "$container" ] && command -v fzf &> /dev/null; then
        container=$(docker ps -a --format "{{.Names}}" | fzf --prompt="Select Container (Logs) > ")
    fi
    [ -z "$container" ] && return
    docker logs -f --tail 100 "$container"
}
# ビルドしてからデタッチモードで起動
alias dcub='docker compose up -d --build'

# ログを全表示（compose用）
alias dcl='docker compose logs -f'

unalias dce 2>/dev/null
dce() {
    local service
    service=$(docker compose ps --services | fzf --prompt="Select Service (Exec) > ")
    [ -n "$service" ] && docker compose exec "$service" /bin/bash || docker compose exec "$service" /bin/sh
}
