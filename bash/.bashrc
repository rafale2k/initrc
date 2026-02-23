#!/bin/bash
# 1. 環境変数の読み込み
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env
[[ -f /root/.dotfiles_env ]] && source /root/.dotfiles_env

# 2. パスの強制追加
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH="$HOME/.local/bin:$PATH"
export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$DOTFILES_PATH/bin:$PATH"

# 3. Oh My Bash の設定
export OSH=$HOME/.oh-my-bash

if [ -f "$OSH/oh-my-bash.sh" ]; then
    # --- ここがポイント：OMBを呼ぶ前にエラーの元を封じる ---
    export PROMPT_COMMAND=""
    source "$OSH/oh-my-bash.sh"
    # OMBが勝手にセットした壊れたフックを、読み込み直後に無効化する
    unset -f __zoxide_hook 2>/dev/null
#else
#    if command -v curl >/dev/null; then
#        echo "🛠️  Fixing Oh My Bash installation..."
#        curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash -s -- --unattended
#    fi
fi

# 4. 共通ローダー
# 事前に変数をエクスポートしておく
export DOTFILES_PATH="$HOME/dotfiles"

if [[ -f "$DOTFILES_PATH/common/loader.sh" ]]; then
    source "$DOTFILES_PATH/common/loader.sh"
fi

# 5. Zoxide の安全な初期化（最後に行う）
# --- 修正後の Zoxide 初期化 (root環境用) ---
if command -v zoxide >/dev/null 2>&1; then
    # --no-aliases を使いつつ、自動フックを PROMPT_COMMAND に追加させない
    eval "$(zoxide init bash --no-aliases)"
    
    # 暴走の元凶 PROMPT_COMMAND から _zoxide_hook を除去する
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook;/}"
    PROMPT_COMMAND="${PROMPT_COMMAND//_zoxide_hook/}"
    
    # エイリアスだけ手動で設定
    alias z='__zoxide_z'
    alias zi='zi'
fi
