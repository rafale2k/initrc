#!/bin/bash

# [h] 自分のエイリアスと関数を fzf で検索して実行する
h() {
    local cmd
    # 自分の dotfiles 関連ファイルから alias と function を抽出
    cmd=$(grep -rE "^(alias|function|[a-zA-Z0-9_-]+\(\))" ~/dotfiles/common/ ~/dotfiles/zsh/ ~/dotfiles/bash/ \
        | sed 's/.*:\(alias \+[^=]\+\)=.*/\1/g' \
        | sed 's/.*:\([a-zA-Z0-9_-]\+\)()\( {\|.*\)/\1/g' \
        | grep -vE "^(if|else|then|fi|unalias)" \
        | sort -u \
        | fzf --prompt="🔍 Search Alias/Function > " --height 40% --reverse)

    [ -z "$cmd" ] && return

    # 選択したコマンドを表示して実行
    echo -e "\033[32m🚀 Executing:\033[0m $cmd"
    print -s "$cmd" # Zshの履歴に追加（矢印上で戻れるように）
    eval "$cmd"
}

# [ha] 単純に一覧を色付きで表示するだけ（サクッと見たい時）
alias ha="grep -rE '^(alias|function)' ~/dotfiles/common/ | ccze -A 2>/dev/null || grep -rE '^(alias|function)' ~/dotfiles/common/"
