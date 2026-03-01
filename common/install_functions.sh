#!/bin/bash
# common/install_functions.sh

# --- 1. リポジトリ追加フェーズ ---
setup_os_repos() {
    echo "⚙️  Configuring repositories for $PM..."
    case "$PM" in
        "apt")
            ${SUDO_CMD} apt update -y -qq
            ${SUDO_CMD} apt install -y -qq wget gnupg curl ca-certificates
            ${SUDO_CMD} mkdir -p /etc/apt/keyrings
            # eza, docker, glow のリポジトリ追加 (省略せず実行)
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | ${SUDO_CMD} tee /etc/apt/sources.list.d/gierens.list > /dev/null
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO_CMD} gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | ${SUDO_CMD} tee /etc/apt/sources.list.d/docker.list > /dev/null
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

# --- 2. Oh My Zsh 本体のセットアップ (NEW) ---
setup_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "🌈 Installing Oh My Zsh (headless mode)..."
        # --unattended: 勝手に zsh を起動させない / --keep-zshrc: 君の .zshrc を上書きさせない
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    fi
}

# --- 3. 一括インストールフェーズ ---
install_all_packages() {
    echo "🛠️  Installing all tools and packages..."
    local pkgs="tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras bat glow"
    
    case "$PM" in
        "apt")
            ${SUDO_CMD} apt install -y $pkgs fd-find eza docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "dnf")
            ${SUDO_CMD} dnf install -y --allowerasing $pkgs fd-find docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            # eza binary fallback
            if ! command -v eza &>/dev/null; then
                curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
                tar -xzf /tmp/eza.tar.gz -C /tmp && ${SUDO_CMD} mv /tmp/eza /usr/local/bin/ && chmod +x /usr/local/bin/eza
            fi
            ;;
    esac
}

# --- 4. AIツールのセットアップ ---
setup_ai_tools() {
    echo "🤖 Setting up AI tools (llm)..."
    if command -v pipx >/dev/null 2>&1; then
        pipx install llm --force || pipx install llm
        pipx inject llm llm-gemini || true
    fi
}

# --- 5. 設定配備 & サブモジュールリンク ---
deploy_configs() {
    echo "🖇️  Deploying configuration files..."
    ln -sf "$DOTPATH/bash/.bashrc" "$HOME/.bashrc"
    ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTPATH/configs/vimrc" "$HOME/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$HOME/.gitconfig"

    # サブモジュールのプラグインをリンク
    echo "🔗 Linking zsh plugins from submodules..."
    local zsh_custom_plugins="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$zsh_custom_plugins"
    for plugin_path in "$DOTPATH/zsh/plugins"/*; do
        if [ -d "$plugin_path" ]; then
            ln -sf "$plugin_path" "$zsh_custom_plugins/$(basename "$plugin_path")"
        fi
    done

    # bin/ の展開
    mkdir -p "$HOME/bin"
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$HOME/bin/$(basename "$script")"
            [ ! -L "$script" ] && chmod +x "$script" 2>/dev/null || true
        fi
    done
    # Ubuntu 用の bat/fd 補完
    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
    fi
}
