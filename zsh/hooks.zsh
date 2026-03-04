# shellcheck shell=bash
# shellcheck disable=SC2034,SC2148,SC1090,SC1091
# --- zsh/hooks.zsh ---

# TokyoNight パレット定義 (root用)
set_tokyo_night_colors() {
    # 0-7: 標準色
    printf '\e]4;0;#1a1b26\a'   # 0: Black (Background)
    printf '\e]4;1;#f7768e\a'   # 1: Red
    printf '\e]4;2;#9ece6a\a'   # 2: Green
    printf '\e]4;3;#e0af68\a'   # 3: Yellow
    printf '\e]4;4;#7aa2f7\a'   # 4: Blue
    printf '\e]4;5;#bb9af7\a'   # 5: Magenta
    printf '\e]4;6;#7dcfff\a'   # 6: Cyan
    printf '\e]4;7;#a9b1d6\a'   # 7: White (Foreground)

    # 8-15: 明るい色 (Bright)
    printf '\e]4;8;#414868\a'   # 8: Bright Black
    printf '\e]4;9;#f7768e\a'   # 9: Bright Red
    printf '\e]4;10;#9ece6a\a'  # 10: Bright Green
    printf '\e]4;11;#e0af68\a'  # 11: Bright Yellow
    printf '\e]4;12;#7aa2f7\a'  # 12: Bright Blue
    printf '\e]4;13;#bb9af7\a'  # 13: Bright Magenta
    printf '\e]4;14;#7dcfff\a'  # 14: Bright Cyan
    printf '\e]4;15;#c0caf5\a'  # 15: Bright White

    # 特殊色の同期
    printf '\e]10;#c0caf5\a'    # 文字色 (Foreground)
    printf '\e]11;#1a1b26\a'    # 背景色 (Background)
    printf '\e]12;#c0caf5\a'    # カーソル
}

# Monokai Dark パレット定義 (一般ユーザー用)
set_monokai_colors() {
    # 0-7: 標準色
    printf '\e]4;0;#272822\a'   # 0: Black (Background)
    printf '\e]4;1;#f92672\a'   # 1: Pink (Red)
    printf '\e]4;2;#a6e22e\a'   # 2: Green
    printf '\e]4;3;#f4bf75\a'   # 3: Orange (Yellow)
    printf '\e]4;4;#66d9ef\a'   # 4: Light Blue (Blue)
    printf '\e]4;5;#ae81ff\a'   # 5: Purple (Magenta)
    printf '\e]4;6;#a1efe4\a'   # 6: Aqua (Cyan)
    printf '\e]4;7;#f8f8f2\a'   # 7: White (Foreground)

    # 8-15: 明るい色 (Bright)
    printf '\e]4;8;#75715e\a'   # 8: Gray
    printf '\e]4;9;#f92672\a'   # 9: Bright Pink
    printf '\e]4;10;#a6e22e\a'  # 10: Bright Green
    printf '\e]4;11;#f4bf75\a'  # 11: Bright Orange
    printf '\e]4;12;#66d9ef\a'  # 12: Bright Light Blue
    printf '\e]4;13;#ae81ff\a'  # 13: Bright Purple
    printf '\e]4;14;#a1efe4\a'  # 14: Bright Aqua
    printf '\e]4;15;#f9f8f5\a'  # 15: Bright White

    # 特殊色の同期
    printf '\e]10;#f8f8f2\a'    # 文字色 (Foreground)
    printf '\e]11;#272822\a'    # 背景色 (Background)
    printf '\e]12;#f92672\a'    # カーソル
}

# ユーザーによって適用する関数を決定
if [ "$EUID" -eq 0 ]; then
    CURRENT_THEME_FUNC="set_tokyo_night_colors"
else
    CURRENT_THEME_FUNC="set_monokai_colors"
fi

# 1. 起動時に即時実行
$CURRENT_THEME_FUNC

# 2. Rlogin 等で色が剥がれないよう precmd (プロンプト表示前) に登録
autoload -Uz add-zsh-hook
add-zsh-hook precmd "$CURRENT_THEME_FUNC"
