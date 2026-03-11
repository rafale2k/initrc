#!/bin/bash

# 改造前にファイルを退避させる関数
# 使い方: bu ~/.zshrc
#!/bin/bash

# 改造前にファイルを退避させる関数
bu() {
    local target_file="$1"
    local backup_dir="$HOME/.dotfiles_backup/manual"
    
    if [ -z "$target_file" ] || [ ! -e "$target_file" ]; then
        echo "❌ Usage: bu <file_path> (File must exist)"
        return 1
    fi

    mkdir -p "$backup_dir"

    # タイムスタンプ付きでコピー
    local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
    local filename; filename=$(basename "$target_file")
    local backup_path="$backup_dir/${filename}_${timestamp}.bak"

    cp -r "$target_file" "$backup_path"
    echo "✅ Backup created: $backup_path"

    # --- お掃除機能 (30日以上前のバックアップを削除) ---
    # ユーザーの手を止めないよう、静かに実行
    find "$backup_dir" -name "*.bak" -type f -mtime +30 -delete 2>/dev/null
}

# 古い順で見やすく表示 (eza の流儀)
alias bulist='eza -la --sort oldest $HOME/.dotfiles_backup/manual'

eb() {
    bu "$1" && n "$1"
}
