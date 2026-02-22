if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="powerlevel10k/powerlevel10k"
    
    [[ -f "$DOTFILES_PATH/zsh/.p10k.zsh" ]] && source "$DOTFILES_PATH/zsh/.p10k.zsh"
    
    DISABLE_AUTO_UPDATE="true"
    COMPL_WAITING_DOTS="false"
    plugins=(git sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
    
    source $ZSH/oh-my-zsh.sh
    export ZSH_COMPDUMP_LOADED=1
fi
