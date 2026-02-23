#!/bin/bash
# --- common/loader.sh ---

# 1. パスの確定
export DOTFILES_PATH="$HOME/dotfiles"
COMMON_DIR="$DOTFILES_PATH/common"

# 2. 共通スクリプト (_n や _git) の読み込み
if [ -d "$COMMON_DIR" ]; then
    for f in "$COMMON_DIR"/_*.sh; do
        [ -r "$f" ] && source "$f"
    done
fi

# 3. Zsh 固有設定の読み込み
if [ -n "$ZSH_VERSION" ]; then
<<<<<<< HEAD
    DOT_DIR="${${(%):-%x}:a:h:h}"
    COMMON_DIR="${${(%):-%x}:a:h}"
else
    # --- Bash 用のパス取得をより堅牢に ---
    # BASH_SOURCE が取れない場合を考慮し、pwd から推測するフォールバックを追加
    SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
    COMMON_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    DOT_DIR="$(cd "$COMMON_DIR/.." && pwd)"
=======
    ZSH_DIR="$DOTFILES_PATH/zsh"
    # 背景色 (hooks) -> エイリアス (aliases) -> プロンプト (_p10k) の順で強制実行
    [ -f "$ZSH_DIR/hooks.zsh" ]   && source "$ZSH_DIR/hooks.zsh"
    [ -f "$ZSH_DIR/options.zsh" ] && source "$ZSH_DIR/options.zsh"
    [ -f "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh"
    [ -f "$ZSH_DIR/_p10k.zsh" ]   && source "$ZSH_DIR/_p10k.zsh"
>>>>>>> e912daa (feat: v1.7.0 - Support AI-optimized Bash/Zsh loader and RHEL/root environment stability)
fi

# 4. Bash 固有設定 (もし Bash なら)
if [ -n "$BASH_VERSION" ]; then
    BASH_DIR="$DOTFILES_PATH/bash"
    [ -f "$BASH_DIR/.bashrc" ] && source "$BASH_DIR/.bashrc"
fi
