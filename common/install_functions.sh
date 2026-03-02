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
    
    # 実行ユーザーのホームディレクトリを確実に取得
    local TARGET_HOME=$HOME
    # rootユーザーの場合は /root 、一般ユーザーなら /home/user になる
    echo "Deploying configs to: $TARGET_HOME"
    echo "Using DOTPATH: $DOTPATH"
    
    # --- 1. 標準的なシンボリックリンクの作成 ---
    ln -sf "$DOTPATH/bash/.bashrc" "$TARGET_HOME/.bashrc"
    ln -sf "$DOTPATH/zsh/.zshrc" "$TARGET_HOME/.zshrc"
    ln -sf "$DOTPATH/configs/vimrc" "$TARGET_HOME/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$TARGET_HOME/.gitconfig"
    ln -sf "$DOTPATH/configs/inputrc" "$TARGET_HOME/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$TARGET_HOME/.gitignore_global"

    # --- 2. パス置換が必要な設定 (nanorc) のデプロイ ---
    if [ -f "$DOTPATH/configs/nanorc" ]; then
        echo "🔧 Injecting path into nanorc..."
        # __DOTPATH__ を実際の絶対パスに変換して、ターゲットのホームに書き出す
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/configs/nanorc" > "$TARGET_HOME/.nanorc"
    fi

    # --- 3. Oh-My-Zsh カスタム設定のリンク ---
    echo "🔗 Linking zsh plugins/themes from submodules..."
    local zsh_custom="$TARGET_HOME/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
         
    for plugin_path in "$DOTPATH/zsh/plugins"/*; do
        [ -d "$plugin_path" ] && ln -sf "$plugin_path" "$zsh_custom/plugins/$(basename "$plugin_path")"
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sf "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    # --- 4. 自作バイナリ (bin/) のデプロイ ---
    mkdir -p "$TARGET_HOME/bin"
    echo "🚀 Linking scripts to $TARGET_HOME/bin..."
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$TARGET_HOME/bin/$(basename "$script")"
            # シンボリックリンク本体ではなく、実体ファイルに実行権限を付与
            if [ ! -L "$script" ]; then
                chmod +x "$script" 2>/dev/null || true
            fi
        fi
    done

    # --- 5. OS固有のエイリアス作成 (bat, fd) ---
    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$TARGET_HOME/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$TARGET_HOME/bin/fd"
    fi

    echo "✅ Configuration deployment completed for $TARGET_HOME"
}

setup_root_loader() {
    if [ "$OS" != "mac" ]; then
        echo "🎨 Configuring loader and PATH for root user..."
        
        # 共通の読み込み行とPATH設定を定義
        local LOADER_CMD="source '${DOTPATH}/common/loader.sh'"
        local PATH_CMD="export PATH=\"\$HOME/bin:\$PATH\""

        # .bashrc と .zshrc 両方に対して処理を行う
        for rcfile in "/root/.bashrc" "/root/.zshrc"; do
            ${SUDO_CMD} bash -c "
                if [ -f $rcfile ]; then
                    # loader.sh の読み込み設定
                    grep -q 'loader.sh' $rcfile || echo '$LOADER_CMD' >> $rcfile
                    # PATHの設定（~/bin を優先）
                    grep -q 'export PATH=' $rcfile || echo '$PATH_CMD' >> $rcfile
                    echo '✅ Updated $rcfile'
                fi
            "
        done
    fi
}
