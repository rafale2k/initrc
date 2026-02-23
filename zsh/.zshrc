# 1. Instant Prompt (最速表示用) - これは先頭でOK
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. 基本パスと環境変数
export ZSH="$HOME/.oh-my-zsh"
export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$DOTFILES_PATH/bin:$PATH"

# 3. テーマ指定
ZSH_THEME="powerlevel10k/powerlevel10k"

# 4. Oh My Zsh 本体の起動 (ここでテーマやプラグインがロードされる)
source $ZSH/oh-my-zsh.sh

# 5. p10k の詳細設定 (テーマロードの直後に読み込む)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 6. その他のツール・共通設定 (zoxide, loaderなど)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if [[ -f "$DOTFILES_PATH/common/loader.sh" ]]; then
    source "$DOTFILES_PATH/common/loader.sh"
fi
