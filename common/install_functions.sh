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
    echo "🌈 Checking Oh My Zsh..."
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        echo "🚚 Oh My Zsh not found or incomplete. Installing..."
        # 既存の中途半端なディレクトリがあれば削除
        rm -rf "$HOME/.oh-my-zsh"
        
        # 公式インストーラーを非対話モードで実行
        # RUNZSH=no: インストール後に勝手にzshを起動させない
        # CHSH=no: シェル変更を試みない（コンテナでコケる原因）
        export RUNZSH=no
        export CHSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        # インストール後に実体があるか再確認
        if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
            echo "❌ Error: Oh My Zsh installation failed."
            return 1
        fi
    else
        echo "✅ Oh My Zsh is already installed."
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

# --- 6. Rootユーザー用の設定 (共通設定の読み込み) ---
setup_root_loader() {
    if [ "$OS" != "mac" ]; then
        echo "🎨 Configuring loader for root user..."
        # rootの.bashrcにloader.shを読み込む設定を入れる
        # ${SUDO_CMD} を使って権限を確保
        ${SUDO_CMD} bash -c "[ -f /root/.bashrc ] && (grep -q 'loader.sh' /root/.bashrc || echo \"source '${DOTPATH}/common/loader.sh'\" >> /root/.bashrc)"
    fi
}
