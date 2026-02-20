# 1. 保存されたパスを読み込む
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env

# 2. Powerlevel10k インスタントプロンプト (起動爆速化)
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# 3. 背景色リセット（Tokyo Night）
printf '\e]11;#1a1b26\a'

# 4. Oh My Zsh & Powerlevel10k 起動設定
if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # OMZ起動前にテーマを指定
    ZSH_THEME="powerlevel10k/powerlevel10k"
    
    # P10kの設定ファイルを読み込む (ドットファイル内のものを優先)
    [[ -f "$DOTFILES_PATH/zsh/.p10k.zsh" ]] && source "$DOTFILES_PATH/zsh/.p10k.zsh"

    DISABLE_AUTO_UPDATE="true"
    COMPL_WAITING_DOTS="false"
    
    # プラグイン設定
    plugins=(git z sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
    
    source $ZSH/oh-my-zsh.sh
    export ZSH_COMPDUMP_LOADED=1
fi

# 5. 共通設定・エイリアス読み込み (loader.sh)
if [[ -z "$COMMON_ALIASES_LOADED" ]]; then
    [[ -f "$DOTFILES_PATH/common/loader.sh" ]] && source "$DOTFILES_PATH/common/loader.sh"
    export COMMON_ALIASES_LOADED=1
fi

# 6. Zsh 固有の動作設定
setopt HIST_IGNORE_DUPS     # 重複コマンドを履歴に入れない
setopt EXTENDED_HISTORY     # 履歴に実行時刻を記録
HIST_STAMPS="yyyy-mm-dd"
zstyle ':completion:*' menu select # 補完候補を矢印で選べるようにする
export ARCHFLAGS="-arch $(uname -m)"

# 7. Zsh 固有エイリアス (共通化できないもの)
alias zshconfig="nano ~/dotfiles/zsh/.zshrc" # 実体を編集するように変更
alias reload="source ~/.zshrc"

# 8. 背景色の維持 (コマンド実行のたびに再適用)
precmd() {
    # _system.sh で定義した関数があれば実行
    if typeset -f set_tokyo_night_colors > /dev/null; then
        set_tokyo_night_colors > /dev/null 2>&1
    fi
}
