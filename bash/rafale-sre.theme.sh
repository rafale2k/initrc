# shellcheck shell=bash
# --- Rafale SRE Custom Theme (OMB) ---

function _omb_theme_PROMPT_COMMAND() {
    local EXIT_CODE="$?"
    local ROOT_MARKER=""

    # Root判定: 渋赤背景のROOTラベルを生成
    if [ "$EUID" -eq 0 ]; then
        ROOT_MARKER="\[\e[1;38;5;255;48;5;52m\] ROOT \[\e[0m\]"
    fi

    # Powerlineのシンボル (OMB標準のものを利用)
    local PS_SYMBOL='❯'
    [ "$EUID" -eq 0 ] && PS_SYMBOL='#'

    # プロンプトの組み立て (multiline風)
    # 1行目: [ROOT] ユーザー@ホスト:パス
    # 2行目: 記号
    PS1="${ROOT_MARKER}\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;36m\]\w\[\e[0m\]\n${PS_SYMBOL} "
}

# OMBのテーマとして登録
_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
