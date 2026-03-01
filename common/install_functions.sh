#!/bin/bash

setup_os_repos() {
    echo "⚙️  Configuring repositories for $PM..."
    case "$PM" in
        "apt")
            ${SUDO_CMD} apt update -y -qq
            ${SUDO_CMD} apt install -y -qq wget gnupg curl ca-certificates
            ${SUDO_CMD} mkdir -p /etc/apt/keyrings
            local codename
            codename=$(grep "VERSION_CODENAME=" /etc/os-release | cut -d= -f2)
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | ${SUDO_CMD} tee /etc/apt/sources.list.d/gierens.list > /dev/null
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | ${SUDO_CMD} tee /etc/apt/sources.list.d/docker.list > /dev/null
            curl -fsSL https://repo.charm.sh/apt/gpg.key | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | ${SUDO_CMD} tee /etc/apt/sources.list.d/charm.list > /dev/null
            ${SUDO_CMD} apt update -y -qq
            ;;
        "dnf")
            ${SUDO_CMD} dnf install -y -qq epel-release
            ${SUDO_CMD} dnf config-manager --set-enabled crb || true
            ${SUDO_CMD} dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            echo -e "[charm]\nname=Charm\nbaseurl=https://repo.charm.sh/yum/\nenabled=1\ngpgcheck=1\ngpgkey=https://repo.charm.sh/yum/gpg.key" | ${SUDO_CMD} tee /etc/yum.repos.d/charm.repo > /dev/null
            ${SUDO_CMD} dnf makecache
            ;;
    esac
}

setup_oh_my_zsh() {
    echo "🌈 Checking Oh My Zsh..."
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        echo "🚚 Installing Oh My Zsh (headless mode)..."
        rm -rf "$HOME/.oh-my-zsh"
        export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

install_all_packages() {
    echo "🛠️  Installing all tools and packages..."
    local pkgs="tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras bat glow"
    case "$PM" in
        "apt")
            # shellcheck disable=SC2086
            ${SUDO_CMD} apt install -y $pkgs fd-find eza docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "dnf")
            # shellcheck disable=SC2086
            ${SUDO_CMD} dnf install -y --allowerasing $pkgs fd-find docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            if ! command -v eza &>/dev/null; then
                curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
                tar -xzf /tmp/eza.tar.gz -C /tmp && ${SUDO_CMD} mv /tmp/eza /usr/local/bin/ && chmod +x /usr/local/bin/eza
            fi
            ;;
    esac
}

setup_ai_tools() {
    echo "🤖 Setting up AI tools (llm & ginv)..."
    
    if command -v pipx >/dev/null 2>&1; then
        pipx install llm --force || pipx install llm
        pipx inject llm llm-gemini || true
        
        export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
        
        # モデルを 2.5 に更新！
        if command -v llm >/dev/null 2>&1; then
            echo "🎯 Setting default model to gemini-2.5-flash..."
            llm models default gemini-2.5-flash || true
        fi
    fi

    echo "📝 Creating ginv script in $DOTPATH/bin/..."
    mkdir -p "$DOTPATH/bin"
    cat << 'EOF' > "$DOTPATH/bin/ginv"
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ginv 'your question'"
    exit 1
fi
llm "$@"
EOF
    chmod +x "$DOTPATH/bin/ginv"
}

deploy_configs() {
    echo "🖇️  Deploying configuration files..."
    ln -sf "$DOTPATH/bash/.bashrc" "$HOME/.bashrc"
    ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTPATH/configs/vimrc" "$HOME/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTPATH/configs/inputrc" "$HOME/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$HOME/.gitignore_global"

    echo "🔗 Linking zsh plugins/themes from submodules..."
    local zsh_custom="$HOME/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

    for plugin_path in "$DOTPATH/zsh/plugins"/*; do
        [ -d "$plugin_path" ] && ln -sf "$plugin_path" "$zsh_custom/plugins/$(basename "$plugin_path")"
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sf "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    mkdir -p "$HOME/bin"
    # dotfiles/bin 下の既存スクリプトをリンク
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$HOME/bin/$(basename "$script")"
            [ ! -L "$script" ] && chmod +x "$script" 2>/dev/null || true
        fi
    done
    
    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
    fi
}

setup_root_loader() {
    if [ "$OS" != "mac" ]; then
        echo "🎨 Configuring loader for root user..."
        ${SUDO_CMD} bash -c "[ -f /root/.bashrc ] && (grep -q 'loader.sh' /root/.bashrc || echo \"source '${DOTPATH}/common/loader.sh'\" >> /root/.bashrc)"
    fi
}
