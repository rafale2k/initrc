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
