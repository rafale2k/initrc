#!/bin/bash

# =============================================================================
# 1. Oh My Bash (OMB) の設定
# =============================================================================
export OSH="/root/.oh-my-bash"

# 未インストールの場合は自動インストール
if [ ! -d "$OSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/root --unattended
fi

# テーマとプラグイン（プロンプトは後で上書きするのでテーマは何でもOK）
OSH_THEME="powerline-multiline"
completions=(git composer ssh docker docker-compose)
plugins=(git bashmarks colored-man-pages)

# OMB 起動
source "$OSH/oh-my-bash.sh"

# =============================================================================
# 2. 共通エイリアス・環境設定
# =============================================================================
# 共通エイリアスを絶対パスで読み込む
COMMON_PATH="/home/rafale/dotfiles/common/common_aliases.sh"
[[ -f "$COMMON_PATH" ]] && source "$COMMON_PATH"

# 基本環境
export TERM=xterm-256color
HIST_STAMPS='yyyy-mm-dd'
OMB_USE_SUDO=true
ENABLE_CORRECTION="true"

# =============================================================================
# 3. プロンプト・見た目のカスタマイズ (OMBの設定を上書き)
# =============================================================================
# =============================================================================
# 5. プロンプト最終上書き (OMBのテーマに勝つ！)
# =============================================================================

# コマンドの成否判定関数
function get_exit_status() {
    if [ $? -ne 0 ]; then
        echo -e "\[\e[1;31m\][!] " # 失敗したら赤い[!]
    fi
}

# OMBの後に実行されるように、あえて関数の外で export する
# \e[1;38;5;255;48;5;52m = 白文字/渋赤背景
# \e[1;33m = 黄色 (ユーザー)
# \e[1;36m = シアン (パス)
# \e[48;5;52m = 背景色維持

set_my_root_ps1() {
    local EXIT_S="$(if [ $? != 0 ]; then echo "\[\e[1;31m\][!] "; fi)"
    export PS1="${EXIT_S}\[\e[1;38;5;255;48;5;52m\] ROOT \[\e[0m\e[48;5;52m\] \[\e[1;33m\]\u\[\e[1;37m\]@\h \[\e[1;36m\]\w \[\e[0m\e[48;5;52m\] \[\e[0m\]\n\$ "
}

# OMBがプロンプトをいじらないように PROMPT_COMMAND を空にするか上書きする
PROMPT_COMMAND=set_my_root_ps1
# =============================================================================
# 4. Bash固有エイリアス
# =============================================================================
alias b='cd -'
alias bashconfig='nano ~/.bashrc'
alias reload='source ~/.bashrc'
alias s='sudo -E -s'
