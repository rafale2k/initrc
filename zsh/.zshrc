# ------------------------------------------------------------------------------
# .zshrc: プロンプト消失回避・修正版
# ------------------------------------------------------------------------------

# 1. Powerlevel10k インスタントプロンプト (最優先)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# 2. パス定義
typeset -U path
export DOTFILES=$HOME/dotfiles
export PATH="$PATH:$HOME/.local/bin"
export PATH="/usr/local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"

# 3. テーマ選択 (ここを修正！)
# Oh My Zsh のカスタムディレクトリにある場合は、この書き方が一番安定するで。
ZSH_THEME="powerlevel10k/powerlevel10k"

# 4. プラグイン設定
plugins=(
    git
    git-extras
    docker
    docker-compose
    copyfile
    copypath
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# 5. Oh My Zsh の読み込み
source $ZSH/oh-my-zsh.sh

# 6. Powerlevel10k の設定読み込み (テーマが読み込まれた後に実行)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 7. 共通ローダー (自作エイリアスなど)
if [ -f "$DOTFILES/common/loader.sh" ]; then
    source "$DOTFILES/common/loader.sh"
fi
eval "$(zoxide init zsh)"
export EDITOR=nano
