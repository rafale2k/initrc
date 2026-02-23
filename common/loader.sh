#!/bin/bash
# ==========================================
# 共通設定ローダー (Zsh & Bash モジュール対応)
# ==========================================

# 1. パスの特定 (Zsh/Bash両対応)
if [ -n "$ZSH_VERSION" ]; then
    DOT_DIR="${${(%):-%x}:a:h:h}"
    COMMON_DIR="${${(%):-%x}:a:h}"
else
    # --- Bash 用のパス取得をより堅牢に ---
    # BASH_SOURCE が取れない場合を考慮し、pwd から推測するフォールバックを追加
    SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
    COMMON_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    DOT_DIR="$(cd "$COMMON_DIR/.." && pwd)"
fi

# 2. common/_*.sh を一括読み込み (共通)
for f in "$COMMON_DIR"/_*.sh; do
    [ -r "$f" ] && source "$f"
done

# 3. 各シェル固有のディレクトリから自動読み込み
if [ -n "$ZSH_VERSION" ]; then
    # --- Zsh の場合 ---
    ZSH_DIR="$DOT_DIR/zsh"
    if [ -d "$ZSH_DIR" ]; then
        for f in "$ZSH_DIR"/*.zsh; do
            fname=$(basename "$f")
            case "$fname" in
                .zshrc|.p10k.zsh) continue ;; 
                *) [ -r "$f" ] && source "$f" ;;
            esac
        done
    fi
elif [ -n "$BASH_VERSION" ]; then
    # --- Bash の場合 ---
    BASH_DIR="$DOT_DIR/bash"
    if [ -d "$BASH_DIR" ]; then
        for f in "$BASH_DIR"/*.sh; do
            fname=$(basename "$f")
            case "$fname" in
                .bashrc|_omb.sh) continue ;; # _omb.shは本体で明示的に呼ぶため除外
                *) [ -r "$f" ] && source "$f" ;;
            esac
        done
    fi
fi

# 4. Global Gitignore の適用
GITIGNORE_GLOBAL="$COMMON_DIR/gitignore_global"
if [ -r "$GITIGNORE_GLOBAL" ]; then
    git config --global core.excludesfile "$GITIGNORE_GLOBAL"
fi

# 5. ローカル設定
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# 変数のクリーンアップ
unset DOT_DIR COMMON_DIR ZSH_DIR BASH_DIR fname
