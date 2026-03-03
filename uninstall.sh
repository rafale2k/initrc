#!/bin/bash
set -u

# パス確定
DOTPATH=$(cd "$(dirname "$0")" && pwd)
export DOTPATH

# 関数読み込み
if [ -f "$DOTPATH/scripts/uninstall_functions.sh" ]; then
    source "$DOTPATH/scripts/uninstall_functions.sh"
else
    echo "❌ Error: scripts/uninstall_functions.sh not found."
    exit 1
fi

echo "🚀 Starting initrc uninstaller..."

# 実行
remove_initrc_symlinks "$HOME"
remove_initrc_loader "$HOME"

echo "✨ Uninstallation complete. Please run 'exec zsh -l' or 'exec bash -l' to refresh your shell."
