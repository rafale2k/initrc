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

# --- 🛠️ ここが運命の分かれ道：デプロイ関数 ---
deploy_configs() {
    local target_home="${1:-$HOME}"
    [ -z "$target_home" ] || [ "$target_home" = "/" ] && target_home="$HOME"
    
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"

    echo "🖇️  Deploying configuration files to: $target_home"
    
    # .bashrc 処理
    if [ -f "$DOTPATH/bash/.bashrc" ]; then
        echo "🔧 Overwriting .bashrc..."
        # 既存ファイルを一度消すことで競合を回避
        rm -f "$target_home/.bashrc"
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/bash/.bashrc" > "$target_home/.bashrc"
    fi

    # .zshrc 処理
    if [ -f "$DOTPATH/zsh/.zshrc" ]; then
        echo "🔧 Overwriting .zshrc..."
        # Oh My Zsh が作ったファイルを物理的に消す
        rm -f "$target_home/.zshrc"
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/zsh/.zshrc" > "$target_home/.zshrc"
    fi

    # シンボリックリンク
    ln -sf "$DOTPATH/configs/vimrc" "$target_home/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$target_home/.gitconfig"
    ln -sf "$DOTPATH/configs/inputrc" "$target_home/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$target_home/.gitignore_global"
    
    if [ -f "$DOTPATH/configs/nanorc" ]; then
        rm -f "$target_home/.nanorc"
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/configs/nanorc" > "$target_home/.nanorc"
    fi

    # Zsh Custom
    local zsh_custom="$target_home/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
    for d in "$DOTPATH/zsh/plugins"/*; do
        if [ -d "$d" ]; then
            ln -sfn "$d" "$zsh_custom/plugins/$(basename "$d")"
        fi
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    # Bin
    mkdir -p "$target_home/bin"
    for s in "$DOTPATH/bin"/*; do
        if [ -f "$s" ]; then
            ln -sf "$s" "$target_home/bin/$(basename "$s")"
            if [ ! -L "$s" ]; then
                chmod +x "$s" 2>/dev/null || true
            fi
        fi
    done

    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$target_home/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$target_home/bin/fd"
    fi

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
    [ -f "$DOTPATH/templates/.env.example" ] && [ ! -f "$t/.env" ] && cp "$DOTPATH/templates/.env.example" "$t/.env"
    [ -f "$DOTPATH/templates/.gitconfig.local.example" ] && [ ! -f "$t/.gitconfig.local" ] && cp "$DOTPATH/templates/.gitconfig.local.example" "$t/.gitconfig.local"
}
