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
