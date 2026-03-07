#!/bin/bash
# shellcheck shell=bash
# --- bash/options.sh: OMB Setup, Custom Theme & Zoxide Fix ---

export OSH="${OSH:-$HOME/.oh-my-bash}"

# --- [自動テーマデプロイ] ---
if [ -d "$OSH" ]; then
    mkdir -p "$OSH/custom/themes/rafale-sre"
    ln -sf "$DOTPATH/bash/rafale-sre.theme.sh" "$OSH/custom/themes/rafale-sre/rafale-sre.theme.sh"
fi

# shellcheck disable=SC2034
OSH_THEME="rafale-sre"

# shellcheck disable=SC2034
completions=(git composer ssh docker docker-compose)
# shellcheck disable=SC2034
plugins=(git bashmarks colored-man-pages)

# 2. Oh My Bash の起動
if [ -f "$OSH/oh-my-bash.sh" ]; then
    export PROMPT_COMMAND=""
    # shellcheck disable=SC1091
    source "$OSH/oh-my-bash.sh"
    unset -f __zoxide_hook 2>/dev/null
fi

# 3. Zoxide の安全な初期化
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --no-aliases)"
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook;/}"
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook/}"
    alias z='__zoxide_z'
    alias zi='zi'
fi

# 4. 履歴設定
# shellcheck disable=SC2034
HIST_STAMPS='yyyy-mm-dd'
HISTCONTROL=ignoreboth
shopt -s histappend
shopt -s autocd 2>/dev/null

# 5. エイリアス
alias bashconfig='nano ~/.bashrc'
alias reload='exec bash'
