# =============================================================================
# 1. Powerlevel10k インスタントプロンプト (最速で描画を開始)
# =============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# =============================================================================
# 2. Oh My Zsh 基本設定 (読み込み前にフラグを立てる)
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# 更新チェックを無効化して起動を速くする
DISABLE_AUTO_UPDATE="true"
# 補完待ちのドット表示を無効化 (画面のチラつき防止)
COMPLETION_WAITING_DOTS="false"

# 未インストールの場合は自動インストール
if [ ! -d "$ZSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# =============================================================================
# 3. 補完・プラグインの高速化 (compinitキャッシュ)
# =============================================================================
# 補完のキャッシュを有効にし、1日に1回だけ再構築する
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
  compinit -C
else
  compinit
fi

plugins=(
    git z sudo extract docker docker-compose
    zsh-autosuggestions zsh-syntax-highlighting
)

# Oh My Zsh 起動
source $ZSH/oh-my-zsh.sh

# =============================================================================
# 4. 共通設定・エイリアス読み込み
# =============================================================================
# デバッグ表示が残っている場合に強制停止
set +xv

DOTFILES_DIR="$HOME/dotfiles"
[[ ! -f "$DOTFILES_DIR/common/common_aliases.sh" ]] || source "$DOTFILES_DIR/common/common_aliases.sh"

# =============================================================================
# 5. Zsh 固有の動作設定
# =============================================================================
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
HIST_STAMPS="yyyy-mm-dd"

# 補完メニューの選択
zstyle ':completion:*' menu select

# 便利機能
ENABLE_CORRECTION="true"
export ARCHFLAGS="-arch $(uname -m)"

# --- Zsh固有エイリアス ---
alias zshconfig="nano ~/.zshrc"
alias reload="source ~/.zshrc"

# =============================================================================
# 6. P10k 詳細設定 & 背景色制御
# =============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 画面描画と重なってノイズにならないよう、出力を捨てる
precmd() {
    set_terminal_color > /dev/null 2>&1
}
