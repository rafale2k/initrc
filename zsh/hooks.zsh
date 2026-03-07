# shellcheck shell=bash
# --- zsh/hooks.zsh: Event Hooks ---

autoload -Uz add-zsh-hook

# common/_system.sh で定義された関数をフックに登録
if [ "$EUID" -eq 0 ]; then
    # 起動時に即時適用
    set_tokyo_night_colors
    # プロンプト表示のたびに再適用 (色の剥がれ防止)
    add-zsh-hook precmd set_tokyo_night_colors
else
    set_monokai_colors
    add-zsh-hook precmd set_monokai_colors
fi
