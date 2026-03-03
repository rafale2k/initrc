#!/bin/bash

# --- OS・パッケージマネージャーの判定 ---
setup_os_repos() {
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"
    
    echo "🌍 Detected OS: $OS (using $PM)"
    
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring repositories for apt..."
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
        echo "⚙️  Configuring repositories for dnf..."
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

# --- パッケージ一括インストール ---
install_all_packages() {
    echo "🛠️  Installing all tools and packages in bulk..."
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

# --- Oh My Zsh 構築 ---
setup_oh_my_zsh() {
    echo "🌈 Checking Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "🚚 Installing Oh My Zsh (headless mode)..."
        CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

# --- 設定ファイルのデプロイ ---
deploy_configs() {
    local target_home="${1:-$HOME}"
    [ -z "$target_home" ] || [ "$target_home" = "/" ] && target_home="$HOME"
    
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"

    echo "🖇️  Deploying configuration files to: $target_home"
    echo "Using DOTPATH: $DOTPATH"
    
    local rc
    for rc in "bash/.bashrc" "zsh/.zshrc"; do
        local target
        target=$(basename "$rc")
        
        if [ ! -f "$DOTPATH/$rc" ]; then
            echo "⚠️  Skip: $DOTPATH/$rc not found."
            continue
        fi

        local tmp_rc="/tmp/initrc_$target"
        # sed -i は使わず、常にリダイレクトで一時ファイルを作る（OS互換性100%）
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/$rc" > "$tmp_rc"

        if [ ! -f "$target_home/$target" ] || ! grep -q "common/loader.sh" "$target_home/$target"; then
            echo "🔧 Creating/Restoring $target from template..."
            cp "$tmp_rc" "$target_home/$target"
        else
            echo "✨ $target already exists, updating path..."
            # 既存ファイルのパス更新も一時ファイル経由で行う
            local update_tmp="/tmp/update_$target"
            sed "s|__DOTPATH__|$DOTPATH|g" "$target_home/$target" > "$update_tmp"
            mv "$update_tmp" "$target_home/$target"
        fi
        rm -f "$tmp_rc"
    done

    # シンボリックリンク (SC2015 対策で if 文に統一)
    ln -sf "$DOTPATH/configs/vimrc" "$target_home/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$target_home/.gitconfig"
    ln -sf "$DOTPATH/configs/inputrc" "$target_home/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$target_home/.gitignore_global"
    
    if [ -f "$DOTPATH/configs/nanorc" ]; then
        local nano_tmp="/tmp/nanorc_tmp"
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/configs/nanorc" > "$nano_tmp"
        mv "$nano_tmp" "$target_home/.nanorc"
    fi

    # Zsh Custom
    local zsh_custom="$target_home/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
    local plugin_path
    for plugin_path in "$DOTPATH/zsh/plugins"/*; do
        if [ -d "$plugin_path" ]; then
            ln -sfn "$plugin_path" "$zsh_custom/plugins/$(basename "$plugin_path")"
        fi
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    # Bin
    mkdir -p "$target_home/bin"
    local script
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$target_home/bin/$(basename "$script")"
            if [ ! -L "$script" ]; then
                chmod +x "$script" 2>/dev/null || true
            fi
        fi
    done

    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$target_home/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$target_home/bin/fd"
    fi

    deploy_local_configs "$target_home"
}

# (AIツールセットアップ、Loader注入などは変更なしだが、SC2155対策で local を分離)
setup_ai_tools() {
    echo "🤖 Setting up AI tools (llm & ginv)..."
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm
        pipx inject llm llm-gemini
    fi
    
    local ginv_path
    ginv_path="$DOTPATH/bin/ginv"
    cat << 'EOF' > "$ginv_path"
#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: ginv 'your prompt'"
  exit 1
fi
llm -m gemini-2.5-flash "$1"
EOF
    chmod +x "$ginv_path"
}

setup_root_loader() {
    local target_home="${1:-$HOME}"
    [ -z "$target_home" ] || [ "$target_home" = "/" ] && return 0

    local rcfile
    for rcfile in "$target_home/.zshrc" "$target_home/.bashrc"; do
        if [ -f "$rcfile" ]; then
            if ! grep -Fq "common/loader.sh" "$rcfile"; then
                echo "source '$DOTPATH/common/loader.sh'" >> "$rcfile"
            fi
        fi
    done
}

deploy_local_configs() {
    local target_home="$1"
    [ -f "$DOTPATH/templates/.env.example" ] && [ ! -f "$target_home/.env" ] && cp "$DOTPATH/templates/.env.example" "$target_home/.env"
    [ -f "$DOTPATH/templates/.gitconfig.local.example" ] && [ ! -f "$target_home/.gitconfig.local" ] && cp "$DOTPATH/templates/.gitconfig.local.example" "$target_home/.gitconfig.local"
}
