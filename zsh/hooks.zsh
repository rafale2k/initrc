# shellcheck shell=bash
# --- zsh/hooks.zsh ---

# プロンプトが表示される直前に実行
function _my_precmd_hook() {
    # Zsh の特殊変数 $functions を使って存在確認 (Bashの type -t の代わり)
    if (( $+functions[set_monokai_colors] )); then
        set_monokai_colors
    fi
}

# 既存のフックに追加
autoload -Uz add-zsh-hook
add-zsh-hook precmd _my_precmd_hook
