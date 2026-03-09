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
    
    # MacのGitHub Actions環境に居座る /bin/bat への不正リンクを物理的に破壊
    echo "🧹 Wiping ghost symlinks..."
    rm -f "$HOME/bin/eza" "$HOME/bin/bat" "$HOME/bin/fd"

    echo "📦 Installing packages via $PM..."
    case "$PM" in
        "brew") 
            brew install "${common_pkgs[@]}" fd eza bat
            local brew_bin; brew_bin=$(brew --prefix)/bin
            # リンク先を brew の実体に固定
            ln -sf "${brew_bin}/eza" "$HOME/bin/eza"
            ln -sf "${brew_bin}/bat" "$HOME/bin/bat"
            ln -sf "${brew_bin}/fd" "$HOME/bin/fd"
            ;;
        "apt") _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza bat || true ;;
        "dnf") _sudo dnf install -y -q "${common_pkgs[@]}" fd-find eza bat || true ;;
    esac

    # Linux用のパス調整 (Macでは絶対実行しない)
    if [ "$(uname)" = "Linux" ]; then
        echo "🐧 Applying Linux-specific symlinks..."
        [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
        [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
        [ -f /usr/bin/fd-find ] && [ ! -f "$HOME/bin/fd" ] && ln -sf /usr/bin/fd-find "$HOME/bin/fd"
    fi

    local arch; arch=$(uname -m)
    # --- eza ダウンロード (全OS共通フォールバック) ---
    if ! command -v eza >/dev/null 2>&1; then
        echo "⬇️ Downloading eza binary..."
        local eza_os="unknown-linux-gnu"
        [[ "$(uname)" == "Darwin" ]] && eza_os="apple-darwin"
        if curl -fLsS "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-${eza_os}.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null; then
            find "$HOME/bin" -type f -name "eza*" ! -name "*.gz" -exec mv {} "$HOME/bin/eza" \;
            chmod +x "$HOME/bin/eza"
        fi
    fi

    # --- bat/fd ダウンロード (Linux環境でインストールに失敗した場合) ---
    if [ "$(uname)" != "Darwin" ]; then
        if ! command -v bat >/dev/null 2>&1; then
            echo "⬇️ Downloading bat binary..."
            local bat_v="v0.24.0"
            if curl -fLsS "https://github.com/sharkdp/bat/releases/download/${bat_v}/bat-${bat_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null; then
                find "$HOME/bin" -type f -name "bat" ! -name "*.gz" -exec mv {} "$HOME/bin/bat" \;
                chmod +x "$HOME/bin/bat"
            fi
        fi
        if ! command -v fd >/dev/null 2>&1; then
            echo "⬇️ Downloading fd binary..."
            local fd_v="v10.2.0"
            if curl -fLsS "https://github.com/sharkdp/fd/releases/download/${fd_v}/fd-${fd_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null; then
                find "$HOME/bin" -type f -name "fd" ! -name "*.gz" -exec mv {} "$HOME/bin/fd" \;
                chmod +x "$HOME/bin/fd"
            fi
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
llm -m gemini-2.0-flash "$1"
EOF
    chmod +x "$HOME/bin/ginv"
}

deploy_configs() {
    # 既存の関数を維持
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
