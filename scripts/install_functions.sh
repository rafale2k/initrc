#!/bin/bash

# shellcheck disable=SC1091
_sudo() {
    if [ -z "${SUDO_CMD:-}" ]; then "$@"; else $SUDO_CMD "$@"; fi
}

setup_os_repos() {
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring apt..."
        if _sudo apt-get update -qq; then
            _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release xz-utils || true
        fi
        
        # shellcheck source=/dev/null
        local os_id; os_id=$(. /etc/os-release; echo "$ID")
        local codename; codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')

        _sudo mkdir -p /etc/apt/keyrings
        if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | _sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        fi
        
        if _sudo wget -qO- "https://download.docker.com/linux/${os_id}/gpg" | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${os_id} ${codename} stable" | _sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi

    elif [ "$PM" = "dnf" ]; then
        if [ "$OS" = "rhel" ]; then
            _sudo dnf install -y -q epel-release || true
        fi
        _sudo dnf install -y -q xz || true
        _sudo dnf makecache -q || true
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras)
    mkdir -p "$HOME/bin"
    
    echo "📦 Starting Package Installation..."

    # 1. パッケージマネージャーでのインストール
    if command -v brew >/dev/null 2>&1; then
        brew install "${common_pkgs[@]}" fd eza bat || true
    
    # --- ここから追加: Alpine (apk) 対応 ---
    elif command -v apk >/dev/null 2>&1; then
        echo "🏔️  Detected Alpine Linux. Using apk..."
        # Alpine は sudo が最初から入ってないこともあるから、一応確認
        _sudo apk add --no-cache "${common_pkgs[@]}" fd eza bat-extras || true
    # --- ここまで ---

    elif command -v apt-get >/dev/null 2>&1; then
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find bat || true
    elif command -v dnf >/dev/null 2>&1; then
        _sudo dnf install -y -q epel-release || true
        _sudo dnf install -y -q --allowerasing "${common_pkgs[@]}" fd-find bat || true
    fi

    # 2. 名前の正規化 (batcat/bat-extras -> bat, fdfind -> fd)
    # Alpine の bat は 'bat' やったり 'bat-extras' やったりするので柔軟に
    if [ "$(uname)" = "Linux" ]; then
        # bat の解決
        if command -v batcat >/dev/null 2>&1; then
            ln -sf "$(command -v batcat)" "$HOME/bin/bat"
        elif command -v bat >/dev/null 2>&1; then
            ln -sf "$(command -v bat)" "$HOME/bin/bat"
        fi
        
        # fd の解決
        if command -v fdfind >/dev/null 2>&1; then
            ln -sf "$(command -v fdfind)" "$HOME/bin/fd"
        elif command -v fd >/dev/null 2>&1; then
            ln -sf "$(command -v fd)" "$HOME/bin/fd"
        fi
    fi
}

setup_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    local custom_dir="$HOME/.oh-my-zsh/custom"
    mkdir -p "$custom_dir/themes" "$custom_dir/plugins"
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$custom_dir/themes/powerlevel10k"
    
    echo "🔗 Linking Zsh plugins..."
    for p in zsh-autosuggestions zsh-syntax-highlighting history-search-multi-word; do
        if [ -d "$DOTPATH/zsh/plugins/$p" ]; then
            ln -sfn "$DOTPATH/zsh/plugins/$p" "$custom_dir/plugins/$p"
            echo "✅ Linked $p"
        fi
    done
}

setup_ai_tools() {
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm && pipx inject llm llm-gemini
    fi
    cat << 'EOF' > "$HOME/bin/ginv"
#!/bin/bash
[ -z "$1" ] && exit 1
llm "$1" -m gemini-2.5-flash --no-stream
EOF
    chmod +x "$HOME/bin/ginv"
}

deploy_configs() {
    safe_replace() { perl -pe "s|__DOTPATH__|$DOTPATH|g" "$1" > "$2"; }
    safe_replace "$DOTPATH/zsh/.zshrc" "$1/.zshrc"
    safe_replace "$DOTPATH/bash/.bashrc" "$1/.bashrc"
    ln -sfn "$DOTPATH/configs/gitconfig" "$1/.gitconfig"
}

setup_root_loader() {
    _sudo bash -c "cat << 'EOF' > /root/.bashrc_rafale
export DOTPATH='$DOTPATH'
[ -f \"\$DOTPATH/common/loader.sh\" ] && . \"\$DOTPATH/common/loader.sh\"
EOF"
    if ! _sudo grep -q '.bashrc_rafale' /root/.bashrc; then
        _sudo bash -c "echo 'source /root/.bashrc_rafale' >> /root/.bashrc"
    fi
}
