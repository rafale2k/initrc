#!/bin/bash
# scripts/uninstall_functions.sh の修正

remove_initrc_loader() {
    local t="${1:-$HOME}"
    echo "🧹 Final mop-up of Powerlevel10k leftovers..."
    
    for f in "$t/.zshrc" "$t/.bashrc"; do
        if [ -f "$f" ]; then
            # --- 🎯 殲滅パターンをさらに拡大 ---
            # 1. Powerlevel10k の全コメントと設定
            # 2. .p10k.zsh の読み込み設定
            # 3. インスタントプロンプトの設定
            # -i (Linux) または -i '' (Mac) で上書き
            sed -i "/powerlevel10k/Id" "$f" 2>/dev/null || sed -i "" "/powerlevel10k/Id" "$f"
            sed -i "/p10k/Id" "$f" 2>/dev/null || sed -i "" "/p10k/Id" "$f"
            sed -i "/instant prompt/Id" "$f" 2>/dev/null || sed -i "" "/instant prompt/Id" "$f"
            
            # ついでに .p10k.zsh 本体も消しておく
            [ -f "$t/.p10k.zsh" ] && rm "$t/.p10k.zsh" && echo "  🗑️ Removed .p10k.zsh"
            
            echo "  ✅ $f is now purely default."
        fi
    done
}

remove_initrc_symlinks() {
    local t="${1:-$HOME}"
    echo "🔗 Removing symlinks..."

    # 1. 個別のドットファイル
    local dots=(".vimrc" ".gitconfig" ".inputrc" ".gitignore_global" ".nanorc")
    for d in "${dots[@]}"; do
        if [ -L "$t/$d" ]; then
            rm "$t/$d"
            echo "  ✅ Removed symlink: $d"
        fi
    done

    # 2. ~/bin 内のシンボリックリンク（実ファイルは消さないよう -L で判定）
    if [ -d "$t/bin" ]; then
        for s in "$t/bin"/*; do
            if [ -L "$s" ]; then
                # リンク先が今回の DOTPATH 内を指しているかチェック（念のため）
                if readlink "$s" | grep -q "$DOTPATH"; then
                    rm "$s"
                    echo "  ✅ Removed binary link: $(basename "$s")"
                fi
            fi
        done
    fi

    # 3. Oh My Zsh のカスタムプラグイン
    local zsh_custom="$t/.oh-my-zsh/custom"
    if [ -d "$zsh_custom" ]; then
        find "$zsh_custom" -type l -name "*" | while read -r link; do
            if readlink "$link" | grep -q "$DOTPATH"; then
                rm "$link"
            fi
        done
        echo "  ✅ Cleaned Oh My Zsh custom links"
    fi
}
