#!/bin/bash

# -----------------------------------------------------------------------------
# bu: Config File Management System (v2.2 - Fix Zsh parse error)
# -----------------------------------------------------------------------------
bu() {
    local cmd="$1"
    local target="$2"
    local backup_dir="$HOME/.dotfiles_backup/manual"
    
    [ ! -d "$backup_dir" ] && mkdir -p "$backup_dir"

    case "$cmd" in
        "add" | "" | */*)
            # 引数が1つの時、それがパス（/ を含む）かファイル（. を含む）なら target にセット
            if [ -z "$target" ]; then
                if [[ "$cmd" == *"/"* ]] || [[ "$cmd" == *"."* ]]; then
                    target="$cmd"
                fi
            fi

            if [ -z "$target" ] || [ ! -e "$target" ]; then
                echo "❌ Usage: bu [add] <file_path>"
                return 1
            fi

            local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
            local filename; filename=$(basename "$target")
            local backup_path="$backup_dir/${filename}_${timestamp}.bak"

            cp -r "$target" "$backup_path"
            echo "✅ Backup created: $backup_path"
            find "$backup_dir" -name "*.bak" -type f -mtime +30 -delete 2>/dev/null
            ;;

        "diff")
            if [ -z "$target" ] || [ ! -e "$target" ]; then
                echo "❌ Usage: bu diff <file_path>"
                return 1
            fi
            local filename; filename=$(basename "$target")
            local latest; latest=$(find "$backup_dir" -name "${filename}_*.bak" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

            if [ -z "$latest" ]; then
                echo "❌ No backup found for $target"
            else
                echo "🔍 Comparing $target with latest backup ($latest)..."
                if command -v colordiff >/dev/null 2>&1; then
                    diff -u "$latest" "$target" | colordiff
                else
                    diff -u "$latest" "$target"
                fi
            fi
            ;;

        "restore")
            if [ -z "$target" ] || [ ! -e "$target" ]; then
                echo "❌ Usage: bu restore <file_path>"
                return 1
            fi
            local filename; filename=$(basename "$target")
            local latest; latest=$(find "$backup_dir" -name "${filename}_*.bak" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

            if [ -z "$latest" ]; then
                echo "❌ No backup found for $target"
            else
                echo -n "⚠️ Restore $target from $latest? (y/n): "
                read -r answer
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    cp -r "$latest" "$target"
                    echo "✅ Restored $target"
                else
                    echo "Cancelled."
                fi
            fi
            ;;

        *)
            echo "❌ Unknown command: $cmd"
            echo "Usage: bu [add|diff|restore] <file_path>"
            return 1
            ;;
    esac
}

alias bulist='eza -la --sort oldest $HOME/.dotfiles_backup/manual'

eb() {
    bu "$1" && n "$1"
}
