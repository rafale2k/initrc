#!/bin/bash
# ==========================================
# 共通設定: ナビゲーション (Navigation)
# ==========================================

# ディレクトリ移動系
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias b='cd -'
mkcd() { mkdir -p "$1" && cd "$1"; }

# zoxide 設定 (zi)
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
    # eza/ls 自動切り替えプレビュー
    if command -v eza > /dev/null; then
        export _ZO_FZF_OPTS="--preview 'eza -T -L 2 --icons --color=always {2..}' --preview-window=right:50%"
    elif command -v exa > /dev/null; then
        export _ZO_FZF_OPTS="--preview 'exa -T -L 2 --icons --color=always {2..}' --preview-window=right:50%"
    else
        export _ZO_FZF_OPTS="--preview 'ls -p -C --color=always {2..}' --preview-window=right:50%"
    fi
fi

# 🌟 本日の主役: fzf + bat 最強プレビュー連携
# 'fe' (File Edit): batで中身を見ながらファイルを選んでエディタで開く
fe() {
    local file
    local bat_cmd
    local fd_cmd

    # 1. bat コマンド判別
    if command -v batcat &> /dev/null; then
        bat_cmd="batcat"
    elif command -v bat &> /dev/null; then
        bat_cmd="bat"
    else
        bat_cmd="cat"
    fi

    # 2. fd コマンド判別 (Ubuntuはfdfind、他はfd)
    if command -v fdfind &> /dev/null; then
        fd_cmd="fdfind"
    elif command -v fd &> /dev/null; then
        fd_cmd="fd"
    else
        fd_cmd="find . -maxdepth 4 -not -path '*/.*' -o -path './.*' -not -name '.'"
    fi

    # 3. 実行：隠しファイルも含めるが .git は除外する (--hidden)
    # fd ならデフォルトで賢く検索してくれる
    if [[ "$fd_cmd" == *"fd"* ]]; then
        file=$($fd_cmd --type f --hidden --exclude .git | fzf --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}" --preview-window=right:60%)
    else
        file=$($fd_cmd | fzf --preview "$bat_cmd --color=always --style=numbers --line-range=:500 {}" --preview-window=right:60%)
    fi
    
    [ -n "$file" ] && ${EDITOR:-vim} "$file"
}
# 履歴検索（整理してここへ移動）
alias h='history | fzf'
