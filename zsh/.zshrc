# ==========================================
# .zshrc - initrc v1.7.0 (The Master Loader)
# ==========================================

# 1. 基礎パスの設定
export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$DOTFILES_PATH/bin:$PATH"

# 2. 補完設定 (OMZ起動前に定義)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 3. 共通設定ローダーの呼び出し (核心部)
# ここで common/_*.sh と zsh/*.zsh (hooks, aliases, p10k) が順次読み込まれます
if [[ -f "$DOTFILES_PATH/common/loader.sh" ]]; then
    source "$DOTFILES_PATH/common/loader.sh"
fi

# 4. Zoxide の初期化 (loader.sh の後で実行)
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# 5. インスタントプロンプト (存在する場合のみ)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ※ Git のコンフリクトマーカーなどはすべて排除済みです
