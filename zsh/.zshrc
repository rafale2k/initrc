# --- Zsh Config ---
# Oh My Zsh のパス（環境に合わせて調整してください）
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# 共通設定の読み込み
[[ -f ~/dotfiles/common/_navigation.sh ]] && source ~/dotfiles/common/_navigation.sh

# Zoxide の初期化 (これ1行でOK)
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
