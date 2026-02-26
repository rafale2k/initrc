# shellcheck shell=bash
# shellcheck disable=SC2034,SC2148,SC1090,SC1091
# --- zsh/_p10k.zsh ---

if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # テーマ設定 (Powerlevel10k)
    ZSH_THEME="powerlevel10k/powerlevel10k"
    
    # OMZ起動前に p10k の設定ファイルを先行読み込み
    [[ -f "$HOME/dotfiles/zsh/.p10k.zsh" ]] && source "$HOME/dotfiles/zsh/.p10k.zsh"
    
    # プラグイン設定
    plugins=(git sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
    
    # Oh My Zsh 起動
    source $ZSH/oh-my-zsh.sh
    
    export ZSH_COMPDUMP_LOADED=1
fi

# OMZ 読み込み後に再度設定ファイルを適用（上書き防止のダメ押し）
[[ -f "$HOME/dotfiles/zsh/.p10k.zsh" ]] && source "$HOME/dotfiles/zsh/.p10k.zsh"
