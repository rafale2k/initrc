# shellcheck shell=bash
# --- Rafale SRE Custom Theme (OMB) ---

function _omb_theme_PROMPT_COMMAND() {
    local EXIT_CODE="$?"
    local ROOT_MARKER=""
    local EXIT_S=""

    # 終了コードが 0 以外なら赤文字で [!] を表示
    if [ "$EXIT_CODE" -ne 0 ]; then
        EXIT_S="\[\e[1;31m\][!] "
    fi

    # Root判定: 渋赤背景のROOTラベルを生成
    if [ "$EUID" -eq 0 ]; then
        ROOT_MARKER="\[\e[1;38;5;255;48;5;52m\] ROOT \[\e[0m\]"
    fi

    # Powerlineのシンボル
    local PS_SYMBOL='❯'
    [ "$EUID" -eq 0 ] && PS_SYMBOL='#'

    # プロンプトの組み立て
    # 1行目: [!] [ROOT] user@host:path
    # 2行目: symbol
    PS1="${EXIT_S}${ROOT_MARKER}\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;36m\]\w\[\e[0m\]\n${PS_SYMBOL} "
}

# OMBのテーマとして登録
_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
