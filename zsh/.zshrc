# 1. 背景色リセット（rootから戻った時のため）
# Tokyo Night (#1a1b26) に強制指定
printf '\e]11;#1a1b26\a'

# 2. Oh My Zsh 読み込み（二重読み込み防止）
if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # 更新チェックを無効化して速くする
    DISABLE_AUTO_UPDATE="true"
    COMPL_WAITING_DOTS="false"

    # プラグイン設定
    plugins=(git z sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)

    # Oh My Zsh 起動
    source $ZSH/oh-my-zsh.sh
    export ZSH_COMPDUMP_LOADED=1
fi

# 3. p10k 設定読み込み
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 4. 共通設定・エイリアス読み込み
if [[ -z "$COMMON_ALIASES_LOADED" ]]; then
    DOTFILES_DIR="$HOME/dotfiles"
    [[ ! -f "$DOTFILES_DIR/common/common_aliases.sh" ]] || source "$DOTFILES_DIR/common/common_aliases.sh"
    export COMMON_ALIASES_LOADED=1
fi

# 5. Zsh 固有の設定（ここらへんは一瞬で終わる）
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
HIST_STAMPS="yyyy-mm-dd"
zstyle ':completion:*' menu select
export ARCHFLAGS="-arch $(uname -m)"

# --- Zsh固有エイリアス ---
alias zshconfig="nano ~/.zshrc"
alias reload="source ~/.zshrc"

# 6. 背景色がしぶとい時のおまじない（お好みで）
# zsh/.zshrc の一番下あたり
precmd() {
    # 毎回コマンド実行後に Tokyo Night パレットを再適用する
    set_tokyo_night_colors > /dev/null 2>&1
}
