#!/bin/bash
# ==========================================
# 共通設定ローダー (rafale edition)
# ==========================================

# 1. パスの特定 (Zsh/Bash両対応)
if [ -n "$ZSH_VERSION" ]; then
    DOT_DIR="${${(%):-%x}:a:h:h}" # commonの1つ上(dotfiles直下)
    COMMON_DIR="${${(%):-%x}:a:h}"
else
    DOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    COMMON_DIR="$DOT_DIR/common"
fi

# 2. _*.sh を一括読み込み
for f in "$COMMON_DIR"/_*.sh; do
    [ -r "$f" ] && source "$f"
done

# 3. Git設定の動的適用
# dotfiles直下の gitconfig を include する
#GITCONFIG_BASE="$DOT_DIR/gitconfig"
#if [ -r "$GITCONFIG_BASE" ]; then
#    # --get-all を使うことで、登録済みのすべてのパスをチェック対象にする
#    if ! git config --global --get-all include.path | grep -qF "$GITCONFIG_BASE"; then
#        git config --global --add include.path "$GITCONFIG_BASE"
#    fi
#fi

# 4. Global Gitignore の適用
# common/gitignore_global を適用
GITIGNORE_GLOBAL="$COMMON_DIR/gitignore_global"
if [ -r "$GITIGNORE_GLOBAL" ]; then
    git config --global core.excludesfile "$GITIGNORE_GLOBAL"
fi

unset DOT_DIR
unset COMMON_DIR
unset GITCONFIG_BASE
unset GITIGNORE_GLOBAL
