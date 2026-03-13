#!/bin/bash

# -----------------------------------------------------------------------------
# Alias Suggestion System: CD to Zoxide
# -----------------------------------------------------------------------------
cd() {
    # 本来の cd コマンドを実行
    builtin cd "$@" || return
    
    # インタラクティブシェル（人間が操作してる時）かつ
    # zoxide がインストールされている場合のみ発動
    if [[ $- == *i* ]] && command -v z >/dev/null 2>&1; then
        # 3回に1回くらいの頻度でツッコミを入れる（毎回やとうざいからな）
        if [ $(( RANDOM % 3 )) -eq 0 ]; then
            echo -e "\033[0;33m💡 Hint: You have 'zoxide' installed! Try using 'z' or 'j' next time for faster navigation.\033[0m"
        fi
    fi
}
