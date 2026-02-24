#!/bin/bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
    # 1. 非インタラクティブシェルや root の場合は色設定をスキップ
    [[ $- != *i* ]] && return 0
    [ "$EUID" -eq 0 ] && return 0
    [ "$TERM" = "linux" ] && return 0

    # 2. xterm 互換環境でのみ色を設定
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
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

        # --- 特殊色 ---
        printf "\e]11;#1a1b26\a" # 背景
        printf "\e]10;#a9b1d6\a" # 文字
        printf "\e]12;#7aa2f7\a" # カーソル
    fi
}

# 配色を適用（rootの場合は関数内で安全にスキップされる）
set_tokyo_night_colors

# ==========================================
# エイリアス & 関数定義 (rootでも読み込まれる)
# ==========================================

# シェル再起動 (Zsh/Bash判別)
if [ -n "$ZSH_VERSION" ]; then
    alias reload='exec zsh -l'
elif [ -n "$BASH_VERSION" ]; then
    alias reload='source ~/.bashrc'
fi

# 基本操作
alias s='sudo -i'
alias si='sudo -i'
alias ss='sudo -s'
alias path='echo -e ${PATH//:/\\n}'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tokyo='printf "\e]4;0;#1a1b26\a"'

# モダンコマンド置換 (eza)
# 複数のパス候補をチェックして root でも動くようにする
EZA_BIN=$(command -v eza || which /usr/local/bin/eza 2>/dev/null)
if [ -x "$EZA_BIN" ]; then
    alias ls="$EZA_BIN --icons --group-directories-first"
    alias ll="$EZA_BIN -alF --icons --git"
    alias lt='$EZA_BIN --tree -a --icons --git --ignore-glob=".git"'
    alias lt2='$EZA_BIN --tree -a --icons --ignore-glob=".git" --level=2'
    alias la="$EZA_BIN -a --icons --group-directories-first"
else
    alias ll='ls -alF --color=auto'
    alias la='ls -la --color=auto'
fi

# モダンコマンド置換 (bat)
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --theme="Monokai Extended"'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --theme="Monokai Extended"'
fi

# fd エイリアス
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# Nano 拡張 (Monokai背景切り替え)
n() {
    local file bat_cmd
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")

    if [ $# -gt 0 ]; then
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
        nano "$@"
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
    else
        # fzf でファイルを選択
        file=$(fdfind --type f --hidden --exclude .git 2>/dev/null | fzf --prompt="Nano File > " --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}")
        if [ -n "$file" ]; then
            [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
            nano "$file"
            [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
        fi
    fi
}

# ---------------------------------------------------------
# Nano Wrapper (無限ループ対策版)
# ---------------------------------------------------------
nano() {
    # 'command' を使うことで、同名の関数ではなく外部バイナリを強制的に呼ぶ
    if [ $# -gt 0 ] || [ ! -t 0 ]; then
        # 背景を Monokai に
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
        
        command nano "$@"
        
        # 背景を TokyoNight に戻す
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
    else
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#272822\a"
        command nano
        [ "$EUID" -ne 0 ] && printf "\e]4;0;#1a1b26\a"
    fi
}

# ユーティリティ
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'
# 修正箇所: シングルクォートをエスケープせず、シンプルに定義
alias localip="hostname -I | awk '{print \$1}'"
alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

# --- クリップボード連携の最適化 (OS / 環境判別版) ---
clipcopy() {
    local content
    if [[ $# -eq 0 ]]; then
        content=$(cat)
    else
        content=$(cat "$1")
    fi

    # 1. SSH接続中の場合 (Rlogin / OSC 52)
    # SSH_CLIENT または SSH_TTY があればリモートと判断
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        local base64_str=$(echo -n "$content" | base64 | tr -d '\n')
        printf "\e]52;c;%s\a" "$base64_str"
        echo "📋 [Remote] Copied via OSC 52"
        return
    fi

    # 2. ローカル環境の場合 (OSごとに分岐)
    case "$(uname)" in
        "Darwin") # macOS
            echo -n "$content" | pbcopy
            echo "📋 [macOS] Copied via pbcopy"
            ;;
        "Linux")
            if [[ $(grep -i Microsoft /proc/version) ]]; then
                # WSL (Windows Subsystem for Linux)
                echo -n "$content" | clip.exe
                echo "📋 [WSL] Copied via clip.exe"
            elif command -v xclip >/dev/null 2>&1; then
                # 純粋なLinux (GUIあり/xclipインストール済み)
                echo -n "$content" | xclip -selection clipboard
                echo "📋 [Linux] Copied via xclip"
            else
                echo "⚠️  No clipboard tool found. Install xclip or use SSH."
            fi
            ;;
    esac
}
# Oh My Zshのプラグインとの競合を防ぐためエイリアスではなく関数を優先
