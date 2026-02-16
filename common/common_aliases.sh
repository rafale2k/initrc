#!/bin/bash

# ==========================================
# 1. システム・ナビゲーション (共通)
# ==========================================
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias path='echo -e ${PATH//:/\\n}' # PATHを見やすく表示
alias sl='ls'
# 現在のディレクトリを3階層下までツリー表示
alias lt='tree -C -L 3'
# batcat (bat) がインストールされている場合のみエイリアスを貼る
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

# grepをより強力に（検索結果を緑でハイライト）
alias grep='grep --color=auto'

# 'cd -' (一つ前のディレクトリに戻る) を 'b' (back) だけで実行
alias b='cd -'

# mkcd フォルダ名 で、作成と移動を同時に行う
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# --- ログ閲覧の強化 ---
# ccze がインストールされている場合のみエイリアスを有効化
if command -v ccze &> /dev/null; then
    # リアルタイムログをカラー表示
    alias tailf='tail -f "$1" | ccze -A'

    # cat の代わりに色付きで表示する関数
    clog() {
        cat "$1" | ccze -A | less -R
    }
fi

#===========================================
# 2. 安全装置 (うっかりミス防止)
# ==========================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p' # 親ディレクトリも自動作成

# ==========================================
# 3. Git 短縮エイリアス (爆速操作)
# ==========================================
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin main'
alias gpl='git pull origin main'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# ==========================================
# 4. Docker 関連 (最新API v1.53 対応)
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

# コンテナ一覧をきれいに表示 (Upを緑色に強調)
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -e "s/Up/$(printf "\033[32mUp\033[0m")/g"'
# リソース監視 (シンプルに白文字で整列)
alias dtop='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}"'

# ログ表示 (cczeがある場合は色付け)
dlog() {
    if [ -z "$1" ]; then
        echo "使用方法: dlog [コンテナ名]"
        return 1
    fi
    if command -v ccze &> /dev/null; then
        docker logs -f --tail 100 "$1" | ccze -A -C -m ansi
    else
        docker logs -f --tail 100 "$1"
    fi
}
alias dl='dlog'

# fzf を使ったインタラクティブなログ選択
dlf() {
    if ! command -v fzf &> /dev/null; then
        echo "fzf がインストールされていません。"
        return 1
    fi
    local container=$(docker ps -a --format "{{.Names}}" | fzf --prompt="Select Container > ")
    [ -n "$container" ] && dlog "$container"
}

# コンテナに入る
de() { docker exec -it "$1" bash || docker exec -it "$1" sh; }

# 掃除系
alias dstopall='docker stop $(docker ps -q)'
alias dclean='docker system prune -f'
alias dclean-all='docker system prune -a --volumes -f'

# ==========================================
# 5. /docker/ ディレクトリへのショートカット
# ==========================================
alias dls='ls -F --color=auto /docker'
cd-d() {
    if [ -z "$1" ]; then cd /docker && ls -F; else cd "/docker/$1"; fi
}
if [ -n "$ZSH_VERSION" ]; then
    compctl -/ -W /docker cd-d
fi

# ==========================================
# 6. シェル別キーバインド設定
# ==========================================
if [ -n "$ZSH_VERSION" ]; then
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
    bindkey "^R" history-incremental-search-backward
elif [ -n "$BASH_VERSION" ]; then
    bind '"\e[1;5C": forward-word'
    bind '"\e[1;5D": backward-word'
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

alias myip='curl ifconfig.me; echo'

# man ページを Monokai 風に色付けする設定
export LESS_TERMCAP_mb=$'\E[1;31m'      # 点滅開始 -> Monokaiピンク
export LESS_TERMCAP_md=$'\E[1;31m'      # 太字開始 -> Monokaiピンク（見出し）
export LESS_TERMCAP_me=$'\E[0m'         # 終了
export LESS_TERMCAP_so=$'\E[01;44;37m'  # ソリッド（検索ヒットなど）
export LESS_TERMCAP_se=$'\E[0m'         # 終了
export LESS_TERMCAP_us=$'\E[1;36m'      # 下線開始 -> Monokaiシアン
export LESS_TERMCAP_ue=$'\E[0m'         # 終了
# less で Monokai 風の色付けを有効にする
export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
export LESS='-R -i -M -j10'

# 3. 補完を「1回のTab」で即座にリスト表示
set show-all-if-ambiguous on

# --- Rlogin配色切り替え魔法 (管理者識別モード) ---
# --- Rlogin背景色・パレット制御魔法 ---
set_terminal_color() {
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" ]]; then
        if [ "$EUID" -eq 0 ]; then
            # root: 背景(0番)を赤黒、文字(10番)を白
            printf "\033]4;0;#2a0505\007"
            printf "\033]10;#ffffff\007"
        else
            # user: 背景(0番)をTokyo Night、文字(10番)を元の色
            printf "\033]4;0;#1a1b26\007"
            printf "\033]10;#a9b1d6\007"
        fi
    fi
}

# 読み込み時に一度実行
set_terminal_color

# --- Zsh 用のキーバインド (inputrc と挙動を合わせる) ---
if [[ -n "$ZSH_VERSION" ]]; then
    # 上下キーで「入力中の文字から始まる履歴」を検索
    # (Oh My Zsh のプラグインと競合しないように設定)
    bindkey '^[[A' up-line-or-search
    bindkey '^[[B' down-line-or-search
 
    # 大文字小文字を区別しない補完の設定 (Zsh版)
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
fi
