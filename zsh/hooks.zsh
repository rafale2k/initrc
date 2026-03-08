# shellcheck shell=bash
# --- zsh/hooks.zsh ---

# プロンプトが表示される直前に実行
function _my_precmd_hook() {
    # SC2154対策: Zsh固有の特殊変数 $functions を Shellcheck に無視させる
    # shellcheck disable=SC2154
    if (( $+functions[set_monokai_colors] )); then
        set_monokai_colors
    fi
}

# 既存のフックに追加
autoload -Uz add-zsh-hook
add-zsh-hook precmd _my_precmd_hook

# コマンド開始時刻を記録
function _my_preexec_latency() {
    timer=${timer:-$SECONDS}
}

# コマンド終了時に差分を計算
function _my_precmd_latency() {
    if [ "$timer" ]; then
        local now=$SECONDS
        local elapsed=$((now - timer))
        if (( elapsed >= 10 )); then
            export LATENCY_ALERT="🐢(${elapsed}s)"
        else
            export LATENCY_ALERT=""
        fi
        unset timer
    fi
}

add-zsh-hook preexec _my_preexec_latency
add-zsh-hook precmd _my_precmd_latency
