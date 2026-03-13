#!/bin/bash

# 自己修復メイン関数
dcheck() {
    local cache_file="/tmp/.dotfiles_last_check_$(whoami)"
    local report_file="/tmp/.dcheck_report_$(whoami)"
    local now; now=$(date +%s)
    local threshold=3600 # 1時間

    if [[ "$1" != "--force" ]]; then
        if [[ -f "$cache_file" ]]; then
            local last_check; last_check=$(cat "$cache_file")
            if (( now - last_check < threshold )); then
                return 0
            fi
        fi
    fi

    (
        local missing_tools=()
        for tool in eza bat fd zoxide fzf tree; do
            if ! command -v "$tool" >/dev/null 2>&1; then
                missing_tools+=("$tool")
            fi
        done

        if [ ${#missing_tools[@]} -gt 0 ]; then
            # 報告用ファイルに不足していたツールを書き込む
            for t in "${missing_tools[@]}"; do
                echo "$t" >> "$report_file"
            done

            # インストール実行
            source "$DOTPATH/scripts/install_functions.sh"
            # 念のため install_all_packages が tool 名を引数に取れれば効率的やけど、
            # 今は既存の関数をそのまま呼ぶ形でいくで
            install_all_packages > /dev/null 2>&1
        fi

        echo "$now" > "$cache_file"
    ) &
    disown # バックグラウンドプロセスをシェル管理から切り離して静かにさせる
}
