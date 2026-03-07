# ------------------------------------------------------------------------------
# .zshrc: 司令塔 (Powerlevel10k & Loader)
# ------------------------------------------------------------------------------

# 1. Powerlevel10k インスタントプロンプト (最優先)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# 2. パス・基本環境変数定義
typeset -U path
export DOTPATH="${DOTPATH:-$HOME/dotfiles}"
export DOTFILES="$DOTPATH"
export ZSH="$HOME/.oh-my-zsh"
export EDITOR=nano

path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  $path
)
export PATH

# 3. Oh My Zsh 設定
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  git-extras
  docker
  docker-compose
  copyfile
  copypath
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-search-multi-word
)

# Oh My Zsh の読み込み
source $ZSH/oh-my-zsh.sh

# 4. Powerlevel10k 設定読み込み
if [[ -f "$DOTPATH/zsh/.p10k.zsh" ]]; then
  source "$DOTPATH/zsh/.p10k.zsh"
elif [[ -f ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
fi

# ------------------------------------------------------------------------------
# 5. 各種設定ファイルの読み込み (外部ファイル化)
# ------------------------------------------------------------------------------

# [Common] 共通設定 (System / Navigation / AI)
# ※ loader.sh が各ファイルを source する想定
if [ -f "$DOTPATH/common/loader.sh" ]; then
  source "$DOTPATH/common/loader.sh"
fi

# [Zsh Specific] Zsh固有設定 (options / hooks)
# ※ 以前 cat で確認した中身を反映させたファイル群
[ -f "$DOTPATH/zsh/options.zsh" ] && source "$DOTPATH/zsh/options.zsh"
[ -f "$DOTPATH/zsh/hooks.zsh" ]   && source "$DOTPATH/zsh/hooks.zsh"

# [Tools] 外部ツール初期化 (fzf 等)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ------------------------------------------------------------------------------
# 6. .zshrc 直書きが必要な特殊設定 (もしあれば)
# ------------------------------------------------------------------------------
# 基本は options.zsh 側に移したが、
# plugins 読み込み順の関係でここに残したいものがあれば追記
