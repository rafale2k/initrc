#!/bin/bash
# shellcheck shell=bash
# ==========================================
# 共通設定: システム基本 (System)
# ==========================================

# 1. fd / fdfind の吸収
if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# 2. bat / batcat の吸収
if ! command -v bat &> /dev/null && command -v batcat &> /dev/null; then
    alias bat='batcat'
fi

# ターミナル配色制御 (Tokyo Night)
set_tokyo_night_colors() {
    [[ $- != *i* ]] && return 0
    [ "$EUID" -eq 0 ] && return 0
    [ "$TERM" = "linux" ] && return 0

    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
        printf "\e]4;0;#1a1b26\a"
        printf "\e]4;8;#414868\a"
        printf "\e]4;1;#f7768e\a"
        printf "\e]4;9;#f7768e\a"
        printf "\e]4;2;#9ece6a\a"
        printf "\e]4;10;#9ece6a\a"
        printf "\e]4;3;#e0af68\a"
        printf "\e]4;11;#e0af68\a"
        printf "\e]4;4;#7aa2f7\a"
        printf "\e]4;12;#7aa2f7\a"
        printf "\e]4;5;#bb9af7\a"
        printf "\e]4;13;#bb9af7\a"
        printf "\e]4;6;#7dcfff\a"
        printf "\e]4;14;#7dcfff\a"
        printf "\e]4;7;#a9b1d6\a"
        printf "\e]4;15;#c0caf5\a"
        printf "\e]11;#1a1b26\a"
        printf "\e]10;#a9b1d6\a"
        printf "\e]12;#7aa2f7\a"
    fi
}

# ターミナル配色制御 (Monokai Dark)
set_monokai_colors() {
    [[ $- != *i* ]] && return 0
    [ "$TERM" = "linux" ] && return 0

    if [[ "$TERM" == "xterm-256color" || "$TERM" == "xterm" || "$TERM" == "screen-256color" ]]; then
        # 0: Black (Backgroundに近い色), 8: Bright Black (Gray)
        printf "\e]4;0;#272822\a"; printf "\e]4;8;#75715e\a"
        # 1/9: Red (Pink)
        printf "\e]4;1;#f92672\a"; printf "\e]4;9;#f92672\a"
        # 2/10: Green
        printf "\e]4;2;#a6e22e\a"; printf "\e]4;10;#a6e22e\a"
        # 3/11: Yellow (Orange)
        printf "\e]4;3;#f4bf75\a"; printf "\e]4;11;#f4bf75\a"
        # 4/12: Blue (Cyan/Light Blue)
        printf "\e]4;4;#66d9ef\a"; printf "\e]4;12;#66d9ef\a"
        # 5/13: Magenta (Purple)
        printf "\e]4;5;#ae81ff\a"; printf "\e]4;13;#ae81ff\a"
        # 6/14: Cyan
        printf "\e]4;6;#a1efe4\a"; printf "\e]4;14;#a1efe4\a"
        # 7/15: White
        printf "\e]4;7;#f8f8f2\a"; printf "\e]4;15;#f9f8f5\a"
        
        # 特殊設定
        printf "\e]11;#272822\a"  # 背景色 (Background)
        printf "\e]10;#f8f8f2\a"  # 前景色 (Foreground)
        printf "\e]12;#f92672\a"  # カーソル色 (Cursor)
    fi
}

# --- 出し分けロジック ---
if [ "$EUID" -eq 0 ]; then
    # rootユーザーはTokyo Night (警告の意味も込めて)
    set_tokyo_night_colors
else
    # 一般ユーザーはMonokai Dark
    set_monokai_colors
fi

# Monokai Dark inspired eza colors
# ur=ユーザー権限(緑), gr=グループ(黄), tr=ツリーの枝(グレー), sn=サイズ(ピンク) etc.
export EZA_COLORS="\
ur=32:gu=32:gr=33:gw=33:tr=38;5;244:sn=35:nb=35:nm=35:da=38;5;248:\
di=36:fi=0:ln=35:pi=33:so=35:bd=33;46:cd=33;43:or=31;40:mi=31;40:\
ex=32:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44"

# LS_COLORS も合わせておくと他のツールも幸せになれる
export LS_COLORS=$EZA_COLORS

# ==========================================
# エイリアス & 関数定義
# ==========================================

# シェル再起動
if [ -n "${ZSH_VERSION:-}" ]; then
    alias reload='exec zsh -l'
elif [ -n "$BASH_VERSION" ]; then
    alias reload='source ~/.bashrc'
fi

# 基本操作
alias s='sudo -i'
alias si='sudo -i'
alias ss='sudo -s'
alias path='echo -e "${PATH//:/\n}"'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- モダンコマンド置換 (eza / bat) ---
# ※ アンインストール後の再インストールでも確実に動くよう $HOME 基準で設定

# 1. eza (ls replacement)
if [ -x "$HOME/bin/eza" ]; then
    unalias ls ll la lt 2>/dev/null
    alias ls='$HOME/bin/eza --icons --group-directories-first'
    alias ll='$HOME/bin/eza -alF --icons --git'
    alias la='$HOME/bin/eza -a --icons --group-directories-first'

    # 関数版 lt: 引数があればその階層まで、なければ全階層を表示
    lt() {
        local depth=""
        # 第1引数が数字なら --level を指定
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            depth="--level=$1"
            shift # 数字を消費して、残りの引数（パス等）を次に回す
        fi
        
        # eza 実行 (残りの引数 "$@" も渡すことでディレクトリ指定にも対応)
        "$HOME/bin/eza" --tree -a --icons --git --ignore-glob=".git" ${depth:+"$depth"} "$@"
    }
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -a'
fi

# 2. bat (cat replacement)
if [ -x "$HOME/bin/bat" ]; then
    unalias cat 2>/dev/null
    alias cat='$HOME/bin/bat --paging=never --theme="Monokai Extended"'
    alias bat='$HOME/bin/bat'
elif command -v batcat &> /dev/null; then
    unalias cat 2>/dev/null
    alias cat='batcat --paging=never'
    alias bat='batcat'
fi

# 3. fd-find
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# --- Git 基本エイリアス (loaderが失敗しても最低限動くように) ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# ---------------------------------------------------------
# Nano Wrapper & Selector
# ---------------------------------------------------------
n() {
    local file bat_cmd fd_cmd bg_color_orig bg_color_nano
    
    # 1. コマンドの実体を変数に格納
    bat_cmd=$(command -v batcat || command -v bat || echo "cat")
    fd_cmd=$(command -v fdfind || command -v fd || echo "find")

    # ユーザーに応じて背景色を定義
    if [ "$EUID" -eq 0 ]; then
        bg_color_orig="#1a1b26" # Tokyo Night (復元用)
        bg_color_nano="#1a1b26" # rootはNano中も変えない（or お好みで変える）
    else
        bg_color_orig="#272822" # Monokai Dark (復元用)
        bg_color_nano="#272822" # 一般ユーザーの常用色
    fi

    # 2. 引数がある場合
    if [ $# -gt 0 ]; then
        # Nano起動前に背景色をセット
        printf "\e]4;0;%s\a" "$bg_color_nano"
        command nano "$@"
        # 終了後に元の色に復元
        printf "\e]4;0;%s\a" "$bg_color_orig"

    # 3. 引数がない場合 (fzfでファイル選択)
    else
        if command -v fzf &> /dev/null; then
            file=$($fd_cmd --type f --hidden --exclude .git 2>/dev/null | \
                   fzf --prompt="Nano File > " \
                       --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}")
            
            if [ -n "$file" ]; then
                printf "\e]4;0;%s\a" "$bg_color_nano"
                command nano "$file"
                printf "\e]4;0;%s\a" "$bg_color_orig"
            fi
        else
            command nano
        fi
    fi
}

# ---------------------------------------------------------
# 外部連携 (Monokai Palette / Clipboard)
# ---------------------------------------------------------
if [ -f "$DOTFILES_PATH/scripts/install_functions.sh" ]; then
    source "$DOTFILES_PATH/scripts/install_functions.sh"
    install_monokai_palette "$DOTFILES_PATH" > /dev/null 2>&1
fi

alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me'

localip() {
    hostname -I | awk '{print $1}'
}

alias du10='du -sh * | sort -hr | head -n 10'
alias mem='ps auxf | sort -nr -k 4 | head -n 10'

clipcopy() {
    local content
    [[ $# -eq 0 ]] && content=$(cat) || content=$(cat "$1")

    if [ -f /.dockerenv ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        local base64_str
        base64_str=$(echo -n "$content" | base64 | tr -d '\n')
        printf "\e]52;c;%s\a" "$base64_str"
        echo "📋 [OSC 52] Copied to host clipboard"
        return
    fi

    case "$(uname)" in
        "Darwin") echo -n "$content" | pbcopy ;;
        "Linux")
            if grep -qi Microsoft /proc/version 2>/dev/null; then
                echo -n "$content" | clip.exe
            elif command -v xclip >/dev/null 2>&1; then
                echo -n "$content" | xclip -selection clipboard
            else
                local b64
                b64=$(echo -n "$content" | base64 | tr -d '\n')
                printf "\e]52;c;%s\a" "$b64"
            fi
            ;;
    esac
}
