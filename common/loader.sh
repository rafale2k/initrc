#!/bin/bash
# --- common/loader.sh ---

# 1. パスの確定
export DOTFILES_PATH="$(cd "$(dirname "${(:-%x):-$0}")/.." && pwd)"
COMMON_DIR="$DOTFILES_PATH/common"

# 2. ローカル環境変数を読み込む (出力は一切出さない)
if [ -f "$DOTFILES_PATH/common/.env.local" ]; then
    source "$DOTFILES_PATH/common/.env.local" > /dev/null 2>&1
fi

# 3. 共通スクリプトの自動読み込み
if [ -d "$COMMON_DIR" ]; then
    for f in "$COMMON_DIR"/_*.sh; do
        # source 時に出力が出てしまうと p10k が警告を出すので、静かに実行
        [ -r "$f" ] && source "$f" > /dev/null 2>&1
    done
fi

# 4. 各シェル固有設定の読み込み
if [ -n "$ZSH_VERSION" ]; then
    ZSH_DIR="$DOTFILES_PATH/zsh"
    [ -r "$ZSH_DIR/hooks.zsh" ]   && source "$ZSH_DIR/hooks.zsh"   > /dev/null 2>&1
    [ -r "$ZSH_DIR/options.zsh" ] && source "$ZSH_DIR/options.zsh" > /dev/null 2>&1
    [ -r "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh" > /dev/null 2>&1
    [ -r "$ZSH_DIR/_p10k.zsh" ]   && source "$ZSH_DIR/_p10k.zsh"   > /dev/null 2>&1

elif [ -n "$BASH_VERSION" ]; then
    BASH_DIR="$DOTFILES_PATH/bash"
fi

# 5. 環境判定とプロンプト・エイリアスの適用
if [ -n "$ZSH_VERSION" ]; then
    alias reload='exec zsh -l'

elif [ -n "$BASH_VERSION" ]; then
    export PROMPT_COMMAND=""
    if [ "$EUID" -eq 0 ]; then
        # 修正箇所: ここでクォートの閉じ忘れがないか確認済み
        export PS1='\[\e[1;37;41m\] ROOT \[\e[0m\] \[\e[01;31m\]\u@\h\[\e[0m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    fi
    alias reload='source ~/.bashrc'
fi

# 6. 変数のクリーンアップ
unset f
