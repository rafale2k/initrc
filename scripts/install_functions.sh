#!/bin/bash

# --- OS・パッケージマネージャーの判定 ---
setup_os_repos() {
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"
    
    if [ "$PM" = "apt" ]; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2)
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
        sudo apt-get update -qq
    elif [ "$PM" = "dnf" ]; then
        if [ -f /etc/dnf/dnf.conf ]; then
            if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
                echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
            fi
        fi
        sudo dnf install -y -q epel-release dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf makecache -q
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras bat)
    if [ "$OS" = "mac" ]; then
        brew install "${common_pkgs[@]}" fd eza docker docker-compose
    elif [ "$PM" = "apt" ]; then
        sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [ "$PM" = "dnf" ]; then
        sudo dnf install -y -q "${common_pkgs[@]}" fd-find docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker 2>/dev/null || true
    fi
}

setup_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

deploy_configs() {
    local target_home="${1:-$HOME}"
    [ -z "$target_home" ] || [ "$target_home" = "/" ] && target_home="$HOME"
    
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"

    echo "🖇️  Deploying configuration files to: $target_home"
    
    # Perl置換関数のエラーハンドリング強化
    safe_replace() {
        local src="$1"
        local dst="$2"
        [ ! -f "$src" ] && { echo "❌ Error: Source $src not found"; return 0; }
        DP="$DOTPATH" perl -pe 's/__DOTPATH__/$ENV{DP}/g' "$src" > "$dst" || echo "⚠️ Warning: Failed to replace $src"
    }

    # .bashrc
    if [ -f "$DOTPATH/bash/.bashrc" ]; then
        echo "🔧 Overwriting .bashrc..."
        rm -f "$target_home/.bashrc"
        safe_replace "$DOTPATH/bash/.bashrc" "$target_home/.bashrc"
    fi

    # .zshrc
    if [ -f "$DOTPATH/zsh/.zshrc" ]; then
        echo "🔧 Overwriting .zshrc..."
        rm -f "$target_home/.zshrc"
        safe_replace "$DOTPATH/zsh/.zshrc" "$target_home/.zshrc"
    fi

    # リンク作成（失敗しても全体を止めない || true を徹底）
    ln -sf "$DOTPATH/configs/vimrc" "$target_home/.vimrc" || true
    ln -sf "$DOTPATH/configs/gitconfig" "$target_home/.gitconfig" || true
    ln -sf "$DOTPATH/configs/inputrc" "$target_home/.inputrc" || true
    ln -sf "$DOTPATH/configs/gitignore_global" "$target_home/.gitignore_global" || true
    
    if [ -f "$DOTPATH/configs/nanorc" ]; then
        rm -f "$target_home/.nanorc"
        safe_replace "$DOTPATH/configs/nanorc" "$target_home/.nanorc"
    fi

    # Zsh Custom
    local zsh_custom="$target_home/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
    for d in "$DOTPATH/zsh/plugins"/*; do
        if [ -d "$d" ]; then
            ln -sfn "$d" "$zsh_custom/plugins/$(basename "$d")" || true
        fi
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    # Bin
    mkdir -p "$target_home/bin"
    for s in "$DOTPATH/bin"/*; do
        if [ -f "$s" ]; then
            ln -sf "$s" "$target_home/bin/$(basename "$s")" || true
            if [ ! -L "$s" ]; then
                chmod +x "$s" 2>/dev/null || true
            fi
        fi
    done

    # local_configs のデプロイを慎重に実行
    deploy_local_configs "$target_home"
}

setup_ai_tools() {
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm
        pipx inject llm llm-gemini
    fi
    local ginv_path="$DOTPATH/bin/ginv"
    cat << 'EOF' > "$ginv_path"
#!/bin/bash
if [ -z "$1" ]; then exit 1; fi
llm -m gemini-2.5-flash "$1"
EOF
    chmod +x "$ginv_path"
}

setup_root_loader() {
    local t="${1:-$HOME}"
    [ -z "$t" ] || [ "$t" = "/" ] && return 0
    for f in "$t/.zshrc" "$t/.bashrc"; do
        if [ -f "$f" ] && ! grep -Fq "common/loader.sh" "$f"; then
            echo "source '$DOTPATH/common/loader.sh'" >> "$f"
        fi
    done
}

deploy_local_configs() {
    local t="$1"
    # templates/ ディレクトリが存在するか、ファイルがあるか、一つずつ || true で守る
    if [ -d "$DOTPATH/templates" ]; then
        [ -f "$DOTPATH/templates/.env.example" ] && [ ! -f "$t/.env" ] && cp "$DOTPATH/templates/.env.example" "$t/.env" || true
        [ -f "$DOTPATH/templates/.gitconfig.local.example" ] && [ ! -f "$t/.gitconfig.local" ] && cp "$DOTPATH/templates/.gitconfig.local.example" "$t/.gitconfig.local" || true
    fi
    # 最後に必ず 0 を返して関数を正常終了させる
    return 0
}
