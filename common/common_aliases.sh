#!/bin/bash

# ==========================================
# 1. ターミナル配色制御 (Tokyo Night)
# ==========================================
# ターミナルの色を Tokyo Night に染める最強魔法
set_tokyo_night_colors() {
    # インタラクティブシェルでない場合は実行しない
    [[ $- != *i* ]] && return

    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" ]]; then
        if [ "$EUID" -ne 0 ]; then
            # --- 16色パレット定義 (0-15番) ---
            printf "\033]4;0;#1a1b26\007"  # Background
            printf "\033]4;8;#414868\007"  # Bright Black (Comments)
            printf "\033]4;1;#f7768e\007"  # Red
            printf "\033]4;9;#f7768e\007"  # Bright Red
            printf "\033]4;2;#9ece6a\007"  # Green
            printf "\033]4;10;#9ece6a\007" # Bright Green
            printf "\033]4;3;#e0af68\007"  # Yellow
            printf "\033]4;11;#e0af68\007" # Bright Yellow
            printf "\033]4;4;#7aa2f7\007"  # Blue
            printf "\033]4;12;#7aa2f7\007" # Bright Blue
            printf "\033]4;5;#bb9af7\007"  # Magenta
            printf "\033]4;13;#bb9af7\007" # Bright Magenta
            printf "\033]4;6;#7dcfff\007"  # Cyan
            printf "\033]4;14;#7dcfff\007" # Bright Cyan
            printf "\033]4;7;#a9b1d6\007"  # White
            printf "\033]4;15;#c0caf5\007" # Bright White

            # --- 直接指定 (トドメ) ---
            printf "\e]11;#1a1b26\a" # 背景色
            printf "\e]10;#a9b1d6\a" # 文字色
            printf "\e]12;#7aa2f7\a" # カーソル色
        fi
    fi
}

# 読み込み時に一度実行
set_tokyo_night_colors

# ==========================================
# 2. システム・ナビゲーション & 基本操作
# ==========================================
# root化: 戻ってきた瞬間にTokyo Nightにリセットする予約付き
alias s='sudo -i; set_tokyo_night_colors'
alias exit='set_tokyo_night_colors; exit'
# Root Aliases (sudo -i / sudo -s)
alias si='sudo -i'
alias ss='sudo -s'

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias sl='ls'
alias b='cd -'
alias path='echo -e ${PATH//:/\\n}'
alias lt='tree -C -L 3'
alias myip='curl ifconfig.me; echo'

# batcat (bat) 切り替え
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

# フォルダ作成と移動を同時に
mkcd() { mkdir -p "$1" && cd "$1"; }

# ログ閲覧 (ccze)
if command -v ccze &> /dev/null; then
    alias tailf='tail -f "$1" | ccze -A'
    clog() { cat "$1" | ccze -A | less -R; }
fi

# ==========================================
# 3. Git エイリアス (2026年仕様)
# ==========================================
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push origin main'
alias gpm='git push origin main'
alias gpl='git pull origin main'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gquick='git add -A && git commit -m "quick update: $(date "+%Y-%m-%d %H:%M:%S")" && git push origin main'
# prefix付きのコミットエイリアス
alias gfeat='git commit -m "feat: "'   # 新機能
alias gfix='git commit -m "fix: "'     # バグ修正
alias gdocs='git commit -m "docs: "'   # ドキュメント修正
alias gstyle='git commit -m "style: "' # 見た目・整形（コードの中身は変えない）
alias gref='git commit -m "refactor: "' # リファクタリング
# コミットメッセージをちゃんと書くための関数
gcm() {
  # 1. 種類（Type）を選択
  local type=$(echo "feat: 新機能\nfix: バグ修正\ndocs: ドキュメント修正\nstyle: 整形\nrefactor: リファクタリング\nchore: 雑事" | fzf --height 40% --reverse --prompt="Commit Type: " | cut -d':' -f1)
  
  # キャンセルした場合
  [ -z "$type" ] && return
  
  # 2. メッセージを入力
  echo -n "Message: "
  read msg
  
  # メッセージが空ならキャンセル
  [ -z "$msg" ] && return
  
  # 3. コミット実行
  git commit -m "$type: $msg"
}

# ==========================================
# 4. Docker 関連 (v1.53対応)
# ==========================================
export DOCKER_API_VERSION=1.53
export DOCKER_HIDE_LEGACY_VERSION_WARNING=true

alias d='docker'
alias dc='docker compose'
alias di='docker images'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -e "s/Up/$(printf "\033[32mUp\033[0m")/g"'

# 最強ログ表示 (dlog/dl)
dl() {
    local container
    if [ -n "$1" ]; then
        container="$1"
    elif command -v fzf &> /dev/null; then
        container=$(docker ps -a --format "{{.Names}}" | fzf --prompt="Select Container > ")
    fi
    [ -z "$container" ] && return
    command -v ccze &> /dev/null && docker logs -f --tail 100 "$container" | ccze -A -C -m ansi || docker logs -f --tail 100 "$container"
}
alias dlog='dl'

# コンテナに入る
alias de='docker exec -it "$1" bash || docker exec -it "$1" sh'

# ==========================================
# 5. 特殊設定 & 便利機能
# ==========================================
alias dls='ls -F --color=auto /docker'
cd-d() {
    if [ -z "$1" ]; then cd /docker && ls -F; else cd "/docker/$1"; fi
}
[ -n "$ZSH_VERSION" ] && compctl -/ -W /docker cd-d

# 安全装置
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Manページの色付け
export LESS_TERMCAP_md=$'\E[1;31m' 
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_us=$'\E[1;36m' 
export LESS_TERMCAP_ue=$'\E[0m'
export LESS='-R -i -M -j10'

# ドットファイル更新
alias update-dots='cd ~/dotfiles && git pull && gquick && cd -'
