# ~/dotfiles/zsh/_p10k.zsh

if [[ -z "$ZSH_COMPDUMP_LOADED" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
<<<<<<< HEAD
    # --- 修正ポイント：ここ ---
    # OMZの仕様上、customディレクトリにある場合はフォルダ名だけでOK
    # もしくは、フォルダ名とファイル名が一致している必要があります
    ZSH_THEME="powerlevel10k" 
    
    # 設定ファイルを OMZ 起動前に読み込む
=======
    # ここで先に設定を読み込んでおく
>>>>>>> e912daa (feat: v1.7.0 - Support AI-optimized Bash/Zsh loader and RHEL/root environment stability)
    [[ -f "$HOME/dotfiles/zsh/.p10k.zsh" ]] && source "$HOME/dotfiles/zsh/.p10k.zsh"
    
    plugins=(git sudo extract docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
    source $ZSH/oh-my-zsh.sh
    export ZSH_COMPDUMP_LOADED=1
fi

# OMZ 読み込み後に「ダメ押し」で再度設定ファイルを当てる
[[ -f "$HOME/dotfiles/zsh/.p10k.zsh" ]] && source "$HOME/dotfiles/zsh/.p10k.zsh"
