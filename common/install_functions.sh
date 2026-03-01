#!/bin/bash
# common/install_functions.sh

# --- 1. リポジトリ追加フェーズ (OS設定) ---
setup_os_repos() {
    echo "⚙️  Configuring repositories for $PM..."
    case "$PM" in
        "apt")
            ${SUDO_CMD} apt update -y -qq
            ${SUDO_CMD} apt install -y -qq wget gnupg curl ca-certificates
            ${SUDO_CMD} mkdir -p /etc/apt/keyrings

            # eza repo
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | ${SUDO_CMD} tee /etc/apt/sources.list.d/gierens.list > /dev/null

            # docker repo
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | ${SUDO_CMD} tee /etc/apt/sources.list.d/docker.list > /dev/null

            # glow repo
            curl -fsSL https://repo.charm.sh/apt/gpg.key | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | ${SUDO_CMD} tee /etc/apt/sources.list.d/charm.list > /dev/null
            
            echo "🔄 Finalizing repository update..."
            ${SUDO_CMD} apt update -y -qq
            ;;
        "dnf")
            # 1. まず確実に存在するパッケージを入れる
            ${SUDO_CMD} dnf install -y --allowerasing $pkgs docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # 2. eza が入らなかった場合、バイナリを直接インストール
            if ! command -v eza &>/dev/null; then
                echo "🚚 eza not found in repos. Installing binary directly..."
                # 最新版のURL（x86_64）を指定
                local EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                curl -Lo /tmp/eza.tar.gz "$EZA_URL"
                tar -xzf /tmp/eza.tar.gz -C /tmp
                ${SUDO_CMD} mv /tmp/eza /usr/local/bin/
                ${SUDO_CMD} chmod +x /usr/local/bin/eza
                rm /tmp/eza.tar.gz
            fi

            # bat & fd symlinks
            mkdir -p "$DOTPATH/bin"
            ln -sf /usr/bin/bat "$DOTPATH/bin/bat"
            ln -sf /usr/bin/fd-find "$DOTPATH/bin/fd"
            ;;
        "brew")
            brew install $pkgs eza docker docker-compose
            ;;
    esac
}

# --- 2. 一括インストールフェーズ ---
install_all_packages() {
    echo "🛠️  Installing all tools and packages..."
    local pkgs="tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras eza bat fd-find glow"
    
    case "$PM" in
        "apt")
            ${SUDO_CMD} apt install -y $pkgs docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            # bat & fd symlinks
            mkdir -p "$DOTPATH/bin"
            [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$DOTPATH/bin/bat"
            [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$DOTPATH/bin/fd"
            ;;
        "dnf")
            ${SUDO_CMD} dnf install -y --allowerasing $pkgs docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            mkdir -p "$DOTPATH/bin"
            ln -sf /usr/bin/bat "$DOTPATH/bin/bat"
            ln -sf /usr/bin/fd-find "$DOTPATH/bin/fd"
            ;;
        "brew")
            brew install $pkgs docker docker-compose
            ;;
    esac
    # docker service start
    [ -d /run/systemd/system ] && ${SUDO_CMD} systemctl enable --now docker || echo "⚠️ Skipping docker service start"
}

# --- 3. その他ツール & 設定フェーズ ---
setup_ai_tools() {
    echo "🤖 Setting up AI tools (llm)..."
    if command -v pipx >/dev/null 2>&1; then
        pipx install llm --force || pipx install llm
        pipx inject llm llm-gemini || true
    fi
}

deploy_configs() {
    echo "🖇️  Deploying configuration files..."
    ln -sf "$DOTPATH/bash/.bashrc" "$HOME/.bashrc"
    ln -sf "$DOTPATH/configs/vimrc" "$HOME/.vimrc"
    ln -sf "$DOTPATH/configs/inputrc" "$HOME/.inputrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTPATH/configs/gitignore_global" "$HOME/.gitignore_global"
    ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"

    echo "🚀 Deploying custom scripts from bin/ to ~/bin/..."
    mkdir -p "$HOME/bin"
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$HOME/bin/$(basename "$script")"
            [ ! -L "$script" ] && chmod +x "$script" 2>/dev/null || true
        fi
    done
}

setup_root_loader() {
    if [ "$OS" != "mac" ]; then
        echo "🎨 Configuring loader for root user..."
        ${SUDO_CMD} bash -c "[ -f /root/.bashrc ] && (grep -q 'loader.sh' /root/.bashrc || echo \"source '${DOTPATH}/common/loader.sh'\" >> /root/.bashrc)"
    fi
}
