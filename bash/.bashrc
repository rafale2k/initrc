#!/bin/bash
# 1. 環境変数の読み込み
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env
[[ -f /root/.dotfiles_env ]] && source /root/.dotfiles_env

# 2. パスの強制追加
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# 3. Oh My Bash の設定
export OSH=$HOME/.oh-my-bash

if [ -f "$OSH/oh-my-bash.sh" ]; then
    # --- ここがポイント：OMBを呼ぶ前にエラーの元を封じる ---
    export PROMPT_COMMAND=""
    source "$OSH/oh-my-bash.sh"
    # OMBが勝手にセットした壊れたフックを、読み込み直後に無効化する
    unset -f __zoxide_hook 2>/dev/null
else
    if command -v curl >/dev/null; then
        echo "🛠️  Fixing Oh My Bash installation..."
        curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash -s -- --unattended
    fi
fi

# 4. 共通ローダー
[[ -f "$DOTFILES_PATH/common/loader.sh" ]] && source "$DOTFILES_PATH/common/loader.sh"

# 5. Zoxide の安全な初期化（最後に行う）
if command -v zoxide >/dev/null 2>&1; then
    # hook（自動記録）を無効にして初期化することで、あのエラーを物理的に防ぐ
    eval "$(zoxide init bash --no-aliases)"
    alias z='__zoxide_z'
fi

