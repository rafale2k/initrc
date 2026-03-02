#!/bin/bash
# ==========================================
# 共通設定: ナビゲーション (Navigation)
# ==========================================

# ディレクトリ移動系
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias b='cd -'
mkcd() { 
    mkdir -p "$1" && cd "$1" || return 1
}

# zoxide用のプレビュー設定（zoxideが存在する場合のみ設定）
if command -v zoxide > /dev/null; then
    if command -v eza > /dev/null; then
        export _ZO_FZF_OPTS="--preview 'eza -T -L 2 --icons --color=always {2..}' --preview-window=right:50%"
    elif command -v exa > /dev/null; then
        export _ZO_FZF_OPTS="--preview 'exa -T -L 2 --icons --color=always {2..}' --preview-window=right:50%"
    else
        export _ZO_FZF_OPTS="--preview 'ls -p -C --color=always {2..}' --preview-window=right:50%"
    fi
fi

# 🌟 本日の主役: fzf + bat 最強プレビュー連携
fe() {
    local file
    local bat_cmd
    
    # 1. bat があるかチェック（batcat は Debian 系やから Alma なら bat かな）
    if command -v bat &> /dev/null; then
        bat_cmd="bat --style=numbers --color=always --line-range :500"
    elif command -v batcat &> /dev/null; then
        bat_cmd="batcat --style=numbers --color=always --line-range :500"
    else
        bat_cmd="cat"
    fi

    # 2. fzf でファイルを選択（find の結果を直接パイプで渡す）
    # バッククォートや複雑な変数代入を避けて、直接パイプラインを書くのが一番安全！
    file=$(find . -maxdepth 4 -not -path '*/.*' -o -path './.*' -not -name '.' 2> /dev/null | fzf \
        --preview "$bat_cmd {}" \
        --preview-window=right:60% \
        --height 80% \
        --layout=reverse --border)

    # 3. 選択されたら開く（n = nvim のエイリアスが効くはず）
    if [[ -n "$file" ]]; then
        # ディレクトリなら cd、ファイルなら n (nvim)
        if [[ -d "$file" ]]; then
            cd "$file" || exit
        else
            n "$file"
        fi
    fi
}

alias h='history | fzf'

# bashでもzshでも動く共通のfcd
fcd() {
  local dir
  # fd(fdfind) があれば優先、なければ find
  local fd_cmd=$(command -v fdfind || command -v fd)
  
  if [ -n "$fd_cmd" ]; then
    # eza があるかチェック
    if command -v eza >/dev/null 2>&1; then
      # 【ezaあり】ツリープレビュー付きの豪華版
      dir=$($fd_cmd --type d --hidden --exclude .git . 2> /dev/null | \
            fzf --height 50% --reverse --border \
                --preview 'eza -T -L 2 --icons --color=always {} | head -30')
    else
      # 【ezaなし】シンプルなリスト版
      dir=$($fd_cmd --type d --hidden --exclude .git . 2> /dev/null | fzf --height 40% --reverse --border)
    fi
  else
    # fd すらない環境用（標準の find）
    dir=$(find . -maxdepth 3 -type d 2> /dev/null | fzf)
  fi

  [ -n "$dir" ] && cd "$dir"
}
