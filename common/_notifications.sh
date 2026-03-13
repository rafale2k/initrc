#!/bin/bash

# -----------------------------------------------------------------------------
# Maintenance Report: Display tools restored by dcheck
# -----------------------------------------------------------------------------
show_maintenance_report() {
    local report_file
    report_file="/tmp/.dcheck_report_$(whoami)"
    
    if [ -f "$report_file" ]; then
        # ツールが重複して書き込まれるのを防ぎつつ表示
        local tools; tools=$(sort "$report_file" | uniq | tr '\n' ' ' | sed 's/ $//; s/ /, /g')
        
        if [ -n "$tools" ]; then
            echo -e "\n\033[0;36m🔧 [dotfiles] Maintenance Report:\033[0m"
            echo -e "\033[0;32m   Restored missing tools: $tools\033[0m"
        fi
        
        # 表示したら消す
        rm -f "$report_file"
    fi
}

# 実行
show_maintenance_report
