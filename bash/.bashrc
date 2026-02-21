#!/bin/bash
# 1. root用のパス読み込み
[[ -f /root/.dotfiles_env ]] && source /root/.dotfiles_env

# =============================================================================
# 2. Oh My Bash (OMB) の設定
# =============================================================================
export OSH="/root/.oh-my-bash"

# 未インストールの場合は自動インストール
if [ ! -d "$OSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/root --unattended
fi

OSH_THEME="powerline-multiline"
completions=(git composer ssh docker docker-compose)
plugins=(git bashmarks colored-man-pages)

# OMB 起動
source "$OSH/oh-my-bash.sh"

# =============================================================================
# 3. 共通設定ローダー (loader.sh) の呼び出し
# =============================================================================
# ここで分割した _git.sh, _docker.sh, _system.sh を一括ロード
# 共通エイリアスとの「被り」は自動的に解消されます
[[ -f "$DOTFILES_PATH/common/loader.sh" ]] && source "$DOTFILES_PATH/common/loader.sh"

# =============================================================================
# 4. root固有の設定・プロンプト
# =============================================================================
export TERM=xterm-256color
HIST_STAMPS='yyyy-mm-dd'

# プロンプト設定 (OMBの上書き)
set_my_root_ps1() {
    local EXIT_CODE=$?
    local EXIT_S=""
    if [ $EXIT_CODE -ne 0 ]; then
        EXIT_S="\[\e[1;31m\][!] " # 失敗したら赤い[!]
    fi
    # 渋赤背景の最強プロンプト
    export PS1="${EXIT_S}\[\e[1;38;5;255;48;5;52m\] ROOT \[\e[0m\e[48;5;52m\] \[\e[1;33m\]\u\[\e[1;37m\]@\h \[\e[1;36m\]\w \[\e[0m\e[48;5;52m\] \[\e[0m\]\n\$ "
}

PROMPT_COMMAND=set_my_root_ps1

# =============================================================================
# 5. Bash/root固有エイリアス (共通化できないものだけ残す)
# =============================================================================
alias bashconfig='nano ~/.bashrc'
alias reload='source ~/.bashrc'

# zoxide の初期化 (bash用)
eval "$(zoxide init bash)"

