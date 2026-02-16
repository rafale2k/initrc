# =============================================================================
# 1. Oh My Zsh & Powerlevel10k セットアップ
# =============================================================================
# P10k インスタントプロンプト設定 (起動高速化)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

# 未インストールの場合は自動インストール
if [ ! -d "$ZSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# テーマ設定
ZSH_THEME="powerlevel10k/powerlevel10k"

# プラグイン設定 (重複を排除して統合)
plugins=(
    git
    z
    sudo
    extract
    docker
    docker-compose
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Oh My Zsh 起動
source $ZSH/oh-my-zsh.sh

# =============================================================================
# 2. 共通設定・エイリアス読み込み
# =============================================================================
DOTFILES_DIR="$HOME/dotfiles"
[[ ! -f "$DOTFILES_DIR/common/common_aliases.sh" ]] || source "$DOTFILES_DIR/common/common_aliases.sh"

# =============================================================================
# 3. Zsh 固有の動作設定
# =============================================================================
# 履歴設定
setopt HIST_IGNORE_DUPS     # 同じコマンドを連続して履歴に残さない
setopt EXTENDED_HISTORY     # 履歴に実行時刻を記録
HIST_STAMPS="yyyy-mm-dd"

# 補完設定
zstyle ':completion:*' menu select
autoload -U colors; colors

# 修正・便利機能
ENABLE_CORRECTION="true"
export ARCHFLAGS="-arch $(uname -m)"

# --- Zsh固有エイリアス ---
alias zshconfig="nano ~/.zshrc"
alias reload="source ~/.zshrc"

# =============================================================================
# Powerlevel10k の詳細設定読み込み
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# プロンプトが表示されるたびに色をチェックして再設定する
precmd() {
    set_terminal_color
}

