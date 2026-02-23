# ==========================================
# .zshrc - Modular Edition (The Master Loader)
# ==========================================

# 1. 基礎パスの設定 (loader.sh が依存するため)
export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$DOTFILES_PATH/bin:$PATH"

# 2. 基本的な環境変数の設定 (OMZ起動前)
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# ------------------------------------------
# 3. 共通設定ローダーの呼び出し
# ------------------------------------------
# ここで以下の順番で読み込まれます：
#   ① common/_*.sh (n() や gl の定義)
#   ② zsh/*.zsh (p10k, aliases, hooks, options)
#
# ※ p10k や OMZ の起動は zsh/_p10k.zsh 内で行われる設計ですね。
LOADER="$DOTFILES_PATH/common/loader.sh"
if [[ -f "$LOADER" ]]; then
    source "$LOADER"
else
    # 万が一パスが通っていない場合、直接 source
    source "$HOME/dotfiles/common/loader.sh"
fi

# ------------------------------------------
# 4. Zoxide などの初期化 (loader.sh の後が安全)
# ------------------------------------------
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# 履歴設定やエイリアスはすでに zsh/*.zsh から読み込まれています
