<<<<<<< HEAD
# ~/dotfiles/zsh/hooks.zsh
autoload -Uz add-zsh-hook

# 背景色リセット
printf '\e]11;#1a1b26\a'

_apply_tokyo_night() {
    if typeset -f set_tokyo_night_colors > /dev/null; then
        set_tokyo_night_colors > /dev/null 2>&1
    fi
}

# precmd にフックとして登録
add-zsh-hook precmd _apply_tokyo_night
=======
# --- zsh/hooks.zsh ---

set_tokyo_night_colors() {
    # TokyoNight パレット定義
    printf '\e]4;0;#1a1b26\a'   # Background
    printf '\e]4;1;#f7768e\a'
    printf '\e]4;2;#9ece6a\a'
    printf '\e]4;3;#e0af68\a'
    printf '\e]4;4;#7aa2f7\a'
    printf '\e]4;5;#bb9af7\a'
    printf '\e]4;6;#7dcfff\a'
    printf '\e]4;7;#a9b1d6\a'   # Foreground
    printf '\e]4;8;#414868\a'
    printf '\e]11;#1a1b26\a'    # 背景色をパレット0番に固定
    printf '\e]10;#c0caf5\a'    # 文字色を明るい白に固定
}

# 実行
set_tokyo_night_colors

# Rlogin で色が剥がれないようにプロンプト表示ごとにも実行
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_tokyo_night_colors
>>>>>>> e912daa (feat: v1.7.0 - Support AI-optimized Bash/Zsh loader and RHEL/root environment stability)
