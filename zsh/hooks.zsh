# 背景色リセット（Tokyo Night）
printf '\e]11;#1a1b26\a'

precmd() {
    if typeset -f set_tokyo_night_colors > /dev/null; then
        set_tokyo_night_colors > /dev/null 2>&1
    fi
}
