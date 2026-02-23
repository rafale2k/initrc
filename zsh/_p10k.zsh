# ~/dotfiles/zsh/_p10k.zsh

if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # --- 修正ポイント：ここ ---
    # OMZの仕様上、customディレクトリにある場合はフォルダ名だけでOK
    # もしくは、フォルダ名とファイル名が一致している必要があります
    ZSH_THEME="powerlevel10k" 
    
    # 設定ファイルを OMZ 起動前に読み込む
    [[ -f "$HOME/dotfiles/zsh/.p10k.zsh" ]] && source "$HOME/dotfiles/zsh/.p10k.zsh"
    
    plugins=(git sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
    
    source $ZSH/oh-my-zsh.sh
    export ZSH_COMPDUMP_LOADED=1
fi
