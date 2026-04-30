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

# 3. zoxide 初期化は common/_navigation.sh に一元化済み
# OMB が PROMPT_COMMAND に __zoxide_hook を注入した場合のみ除去する
if [ -n "${PROMPT_COMMAND:-}" ]; then
    PROMPT_COMMAND="${PROMPT_COMMAND//__zoxide_hook;/}"
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

# ==============================================================================
# root ユーザー専用：防御型エイリアス設定
# rm/cp/mv は common/_system.sh で全ユーザー向けに定義済みのため重複定義しない
# ==============================================================================
if [ "${EUID:-1}" -eq 0 ]; then
    # --- 1. 視認性を上げる（root であることを自覚する） ---
    # eza が ~/bin にない root 環境でも最低限の表示を確保
    alias ls='ls --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'

    # --- 2. ログやプロセスをサクッと確認 ---
    alias df='df -h'
    alias free='free -m'
    alias psg='ps aux | grep -v grep | grep -i'

    # --- 3. ネットワーク ---
    alias ports='ss -tulpn'

    # --- 4. エディタ ---
    alias vi='vim'
    alias edit='vim'
fi
