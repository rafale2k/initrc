# shellcheck shell=bash
# shellcheck disable=SC2034,SC2148,SC1090,SC1091
# --- zsh/hooks.zsh ---

set_tokyo_night_colors() {
    # TokyoNight パレット定義 (16色)
    printf '\e]4;0;#1a1b26\a'   # 0: Background
    printf '\e]4;1;#f7768e\a'
    printf '\e]4;2;#9ece6a\a'
    printf '\e]4;3;#e0af68\a'
    printf '\e]4;4;#7aa2f7\a'
    printf '\e]4;5;#bb9af7\a'
    printf '\e]4;6;#7dcfff\a'
    printf '\e]4;7;#a9b1d6\a'   # 7: Foreground
    printf '\e]4;8;#414868\a'
    printf '\e]4;9;#f7768e\a'
    printf '\e]4;10;#9ece6a\a'
    printf '\e]4;11;#e0af68\a'
    printf '\e]4;12;#7aa2f7\a'
    printf '\e]4;13;#bb9af7\a'
    printf '\e]4;14;#7dcfff\a'
    printf '\e]4;15;#c0caf5\a'

    # 特殊色の同期 (Rlogin等の背景・前景色をパレットに固定)
    printf '\e]10;#c0caf5\a'    # 文字色 (Foreground)
    printf '\e]11;#1a1b26\a'    # 背景色 (Background)
    printf '\e]12;#c0caf5\a'    # カーソル
}

# 起動時に実行
set_tokyo_night_colors

# Rlogin で色が剥がれないようにプロンプト表示ごと (precmd) に実行
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_tokyo_night_colors
