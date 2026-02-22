export TERM=xterm-256color

set_my_root_ps1() {
    local EXIT_CODE=$?
    local EXIT_S=""
    if [ $EXIT_CODE -ne 0 ]; then
        EXIT_S="\[\e[1;31m\][!] "
    fi
    # 渋赤背景の最強プロンプト
    export PS1="${EXIT_S}\[\e[1;38;5;255;48;5;52m\] ROOT \[\e[0m\e[48;5;52m\] \[\e[1;33m\]\u\[\e[1;37m\]@\h \[\e[1;36m\]\w \[\e[0m\e[48;5;52m\] \[\e[0m\]\n\$ "
}

PROMPT_COMMAND=set_my_root_ps1
