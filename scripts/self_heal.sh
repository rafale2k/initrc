#!/bin/bash

# 自己修復メイン関数
dcheck() {
    local cache_file="/tmp/.dotfiles_last_check"
    local now; now=$(date +%s)
    local threshold=3600 # 1時間(3600秒)以内ならスキップ

    # 引数に --force があれば強制実行
    if [[ "$1" != "--force" ]]; then
        if [[ -f "$cache_file" ]]; then
            local last_check; last_check=$(cat "$cache_file")
            if (( now - last_check < threshold )); then
                return 0 # スキップ
            fi
        fi
    fi

    # 実際のチェック（バックグラウンドで静かに実行される想定）
    (
        local missing=0
        for tool in eza bat fd zoxide fzf; do
            if ! command -v "$tool" >/dev/null 2>&1; then
                missing=1
                break
            fi
        done

        if [[ $missing -eq 1 ]]; then
            # エラー時だけ目立つように通知
            echo -e "\n⚠️  [dotfiles] Some tools are missing. Running auto-heal..."
            source "$DOTPATH/scripts/install_functions.sh"
            install_all_packages > /dev/null 2>&1
        fi
        
        echo "$now" > "$cache_file"
    ) & # ← ここでバックグラウンド化！
}
