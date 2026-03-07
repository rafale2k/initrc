# shellcheck shell=bash
# --- zsh/options.zsh: Behavior, Completion & Keybindings ---

# 1. 挙動・履歴設定
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

# shellcheck disable=SC2034
HIST_STAMPS="yyyy-mm-dd"

# 2. 補完設定
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 3. キーバインド
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER != sudo\ * ]]; then
        BUFFER="sudo $BUFFER"
        # shellcheck disable=SC2034
        CURSOR=$#BUFFER
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# 4. 環境変数
alias zshconfig="nano ~/dotfiles/zsh/.zshrc"
alias reload="exec zsh -l"

# SC2155 対策
ARCHFLAGS="-arch $(uname -m)"
export ARCHFLAGS
