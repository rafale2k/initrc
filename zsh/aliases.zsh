# shellcheck shell=zsh
alias zshconfig="nano ~/dotfiles/zsh/.zshrc"
alias reload="source ~/.zshrc"
# Esc 2回で先頭に sudo をつける (Zsh用)
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER != sudo\ * ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$#BUFFER
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line
