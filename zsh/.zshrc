# ==========================================
# .zshrc - initrc v1.7.0 (The Master Loader)
# ==========================================

# 1. 基礎パスの設定
# ------------------------------------------
export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$DOTFILES_PATH/bin:$PATH"

# 2. 補完設定 (OMZ等のプラグインより前に定義)
# ------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 3. Zoxide の初期化
# ------------------------------------------
# loader.sh より前に評価することで、エイリアスの競合を防ぎます
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# 4. インスタントプロンプト / テーマ設定 (p10k)
# ------------------------------------------
# Powerlevel10k などのテーマ設定
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 5. 共通設定ローダーの呼び出し (核心部・最終適用)
# ------------------------------------------
# ここで common/_*.sh を読み込みます。
# 一番最後に読み込むことで reload や ll などのエイリアスを確定させます。
if [[ -f "$DOTFILES_PATH/common/loader.sh" ]]; then
    source "$DOTFILES_PATH/common/loader.sh"
fi

# ※ 以前混入していた Git のコンフリクトマーカー (<<<<<<< HEAD 等) は排除済みです
