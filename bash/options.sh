#!/bin/bash
# shellcheck shell=bash
# --- bash/options.sh: OMB Setup, Custom Theme & Zoxide Fix ---

# 1. Oh My Bash 基本設定
export OSH="${OSH:-$HOME/.oh-my-bash}"

# --- [自動テーマデプロイ] ---
# dotfiles 内のカスタムテーマを OMB の custom ディレクトリにリンクする
if [ -d "$OSH" ]; then
    # テーマ用ディレクトリを作成 (rafale-sre)
    mkdir -p "$OSH/custom/themes/rafale-sre"
    
    # シンボリックリンクを貼る (強制作成)
    # ※ $DOTPATH/bash/rafale-sre.theme.sh が存在することが前提
    ln -sf "$DOTPATH/bash/rafale-sre.theme.sh" "$OSH/custom/themes/rafale-sre/rafale-sre.theme.sh"
fi

# 独自テーマを指定 (OMB 本体読み込み前にセット)
OSH_THEME="rafale-sre"

# OMB のプラグインと補完設定
completions=(git composer ssh docker docker-compose)
plugins=(git bashmarks colored-man-pages)

# 2. Oh My Bash の起動
if [ -f "$OSH/oh-my-bash.sh" ]; then
    # OMB を呼ぶ前に PROMPT_COMMAND を一度クリアして競合を防ぐ
    export PROMPT_COMMAND=""
    # shellcheck disable=SC1091
    source "$OSH/oh-my-bash.sh"
    
    # OMB が勝手にセットした古い zoxide フック等を掃除
    unset -f __zoxide_hook 2>/dev/null
fi

# 3. Zoxide の安全な初期化
# root 環境でのプロンプト崩れを防ぐため、フックを慎重に管理
if command -v zoxide >/dev/null 2>&1; then
    # --no-aliases を使い、自動フックを PROMPT_COMMAND に追加させない
    eval "$(zoxide init bash --no-aliases)"
    
    # 万が一 PROMPT_COMMAND に混入した _zoxide_hook を除去
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook;/}"
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook/}"
    
    # エイリアスは手動で定義 (これが一番安全)
    alias z='__zoxide_z'
    alias zi='zi'
fi

# 4. 履歴・基本挙動設定
HIST_STAMPS='yyyy-mm-dd'
HISTCONTROL=ignoreboth        # 重複とスペース開始を無視
shopt -s histappend           # 履歴を追記モードに
shopt -s autocd 2>/dev/null  # ディレクトリ名だけで移動

# 5. 管理用エイリアス
alias bashconfig='nano ~/.bashrc'
alias reload='exec bash'       # source より exec bash の方が環境が綺麗にリセットされる
