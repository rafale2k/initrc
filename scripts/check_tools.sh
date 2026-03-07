#!/bin/bash
# shellcheck shell=bash
# --- scripts/check_tools.sh: Pre-flight Verification ---

# 呼び出し元 (install.sh) で EXIT_CODE を管理できるよう初期化
EXIT_CODE=0

echo "--- Checking Modern CLI Tools ---"

check_tool() {
    local cmd=$1
    local alt_name=${2:-""}

    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd found at $(command -v "$cmd")"
        "$cmd" --version 2>/dev/null | head -n 1 || echo "Version: N/A"
    elif [[ -n "$alt_name" ]] && command -v "$alt_name" >/dev/null 2>&1; then
        echo "✅ $alt_name found, using as $cmd (OS-specific name)"
        # 必要ならここでエイリアスやシンボリックリンクの作成を検討
    else
        echo "❌ $cmd (or $alt_name) not found in PATH."
        echo "💡 Hint: Ensure your PATH includes /usr/local/bin or ~/bin"
        return 1
    fi
}

# 1. ツールチェック
check_tool "eza" "exa" || EXIT_CODE=1
check_tool "bat" "batcat" || EXIT_CODE=1
check_tool "fd" "fdfind" || EXIT_CODE=1

echo "--- Checking AI Wrappers ---"

TARGET_BIN_DIR="${HOME}/bin"
# ディレクトリがなければ作成（冪等性の確保）
[ ! -d "$TARGET_BIN_DIR" ] && mkdir -p "$TARGET_BIN_DIR"

if [[ -f "$TARGET_BIN_DIR/ginv" ]]; then
    echo "✅ ginv found at $TARGET_BIN_DIR/ginv"
else
    echo "⚠️  ginv not found at $TARGET_BIN_DIR/ginv."
    # ここは警告に留めるか、EXIT_CODE=1 にするか選べる
fi

# 最後にまとめて判定
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "------------------------------------------------"
    echo "🚨 Error: One or more critical tools are missing."
    echo "Please install dependencies before proceeding."
    echo "------------------------------------------------"
    # source して使う場合は return、直接実行なら exit
    (return 0 2>/dev/null) && return 1 || exit 1
fi
