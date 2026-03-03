#!/bin/bash

# --- OS・パッケージマネージャーの判定 ---
setup_os_repos() {
    echo "🌍 Detected OS: $OS (using $PM)"
    
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring repositories for apt..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq wget gnupg curl ca-certificates
        
        # eza (modern ls) repository
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        
        # Docker repository
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
        
        sudo apt-get update -qq
        
    elif [ "$PM" = "dnf" ]; then
        echo "⚙️  Configuring repositories for dnf..."
        # ⚡️ 爆速化のキモ: 並列ダウンロードを有効化
        if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
            echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
        fi
        
        sudo dnf install -y -q epel-release
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf makecache -q
    fi
}

# --- パッケージ一括インストール ---
install_all_packages() {
    echo "🛠️  Installing all tools and packages in bulk..."
    
    # OS間で共通のパッケージリスト
    local pkgs=(
        tree git curl vim nano fzf zsh zoxide jq wget 
        pipx git-extras bat glow fd-find
    )

    if [ "$OS" = "mac" ]; then
        # Mac (Homebrew)
        brew install "${pkgs[@]}" eza docker docker-compose
    elif [ "$PM" = "apt" ]; then
        # Ubuntu/Debian
        # eza は別途追加
        sudo apt-get install -y -qq "${pkgs[@]}" eza docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [ "$PM" = "dnf" ]; then
        # AlmaLinux / RHEL
        # Docker関連も含めて一括投入
        sudo dnf install -y -q "${pkgs[@]}" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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

# --- 設定ファイルのデプロイ (冪等性・SC2155修正済) ---
deploy_configs() {
    local TARGET_HOME="${1:-$HOME}"
    [ -z "$TARGET_HOME" ] || [ "$TARGET_HOME" = "/" ] && TARGET_HOME="$HOME"
    
    echo "🖇️  Deploying configuration files to: $TARGET_HOME"
    
    local rc
    for rc in "bash/.bashrc" "zsh/.zshrc"; do
        local target
        target=$(basename "$rc")
        
        local tmp_rc
        tmp_rc="/tmp/initrc_$(basename "$rc")"
        sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/$rc" > "$tmp_rc"

        if [ ! -f "$TARGET_HOME/$target" ] || ! grep -q "common/loader.sh" "$TARGET_HOME/$target"; then
            echo "🔧 Creating/Restoring $target from template..."
            mv "$tmp_rc" "$TARGET_HOME/$target"
        else
            echo "✨ $target already exists, updating path..."
            sed -i.bak "s|__DOTPATH__|$DOTPATH|g" "$TARGET_HOME/$target" && rm -f "$TARGET_HOME/$target.bak"
            rm -f "$tmp_rc"
        fi
    done

    # 標準リンク
    ln -sf "$DOTPATH/configs/vimrc" "$TARGET_HOME/.vimrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$TARGET_HOME/.gitconfig"
    ln -sf "$DOTPATH/configs/inputrc" "$TARGET_HOME/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$TARGET_HOME/.gitignore_global"
    
    [ -f "$DOTPATH/configs/nanorc" ] && sed "s|__DOTPATH__|$DOTPATH|g" "$DOTPATH/configs/nanorc" > "$TARGET_HOME/.nanorc"

    # Zsh カスタムリンク
    local zsh_custom="$TARGET_HOME/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
    local plugin_path
    for plugin_path in "$DOTPATH/zsh/plugins"/*; do
        if [ -d "$plugin_path" ]; then
            ln -sfn "$plugin_path" "$zsh_custom/plugins/$(basename "$plugin_path")"
        fi
    done
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$zsh_custom/themes/powerlevel10k"

    # Bin リンク
    mkdir -p "$TARGET_HOME/bin"
    local script
    for script in "$DOTPATH/bin"/*; do
        if [ -f "$script" ]; then
            ln -sf "$script" "$TARGET_HOME/bin/$(basename "$script")"
            if [ ! -L "$script" ]; then
                chmod +x "$script" 2>/dev/null || true
            fi
        fi
    done

    # OS固有リンク
    if [ "$PM" = "apt" ]; then
        [ -f "/usr/bin/batcat" ] && ln -sf /usr/bin/batcat "$TARGET_HOME/bin/bat"
        [ -f "/usr/bin/fdfind" ] && ln -sf /usr/bin/fdfind "$TARGET_HOME/bin/fd"
    fi

    deploy_local_configs "$TARGET_HOME"
}

# --- AIツールセットアップ ---
setup_ai_tools() {
    echo "🤖 Setting up AI tools (llm & ginv)..."
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm
        pipx inject llm llm-gemini
    fi
    
    # ginv script creation... (省略せず既存ロジックを維持)
    local ginv_path="$DOTPATH/bin/ginv"
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

# --- Loaderの注入 (二重書き込み防止強化) ---
setup_root_loader() {
    local TARGET_HOME="${1:-$HOME}"
    [ -z "$TARGET_HOME" ] || [ "$TARGET_HOME" = "/" ] && return 0

    local rcfile
    for rcfile in "$TARGET_HOME/.zshrc" "$TARGET_HOME/.bashrc"; do
        if [ -f "$rcfile" ]; then
            if ! grep -Fq "common/loader.sh" "$rcfile"; then
                echo "source '$DOTPATH/common/loader.sh'" >> "$rcfile"
            fi
        fi
    done
}

deploy_local_configs() {
    local TARGET_HOME="$1"
    [ -f "$DOTPATH/templates/.env.example" ] && [ ! -f "$TARGET_HOME/.env" ] && cp "$DOTPATH/templates/.env.example" "$TARGET_HOME/.env"
    [ -f "$DOTPATH/templates/.gitconfig.local.example" ] && [ ! -f "$TARGET_HOME/.gitconfig.local" ] && cp "$DOTPATH/templates/.gitconfig.local.example" "$TARGET_HOME/.gitconfig.local"
}
