# shellcheck shell=bash
# --- zsh/options.zsh: Behavior, Completion & Keybindings ---

# 1. 挙動・履歴設定
setopt HIST_IGNORE_DUPS     # 重複を記録しない
setopt EXTENDED_HISTORY      # 時刻も記録
setopt SHARE_HISTORY         # 複数ターミナルで履歴を共有
HIST_STAMPS="yyyy-mm-dd"

# 2. 補完設定
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 大文字小文字を無視

# 3. キーバインド (Esc 2回で sudo 付与)
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER != sudo\ * ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$#BUFFER
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# 4. Zsh専用エイリアス・環境変数
alias zshconfig="nano ~/dotfiles/zsh/.zshrc"
alias reload="exec zsh -l"
export ARCHFLAGS="-arch $(uname -m)"
