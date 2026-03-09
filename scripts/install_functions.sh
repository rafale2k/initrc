#!/bin/bash

# shellcheck disable=SC1091
_sudo() {
    if [ -z "${SUDO_CMD:-}" ]; then "$@"; else $SUDO_CMD "$@"; fi
}

setup_os_repos() {
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring apt..."
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release xz-utils || true
        
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')
        # shellcheck source=/dev/null
        local os_id; os_id=$(. /etc/os-release; echo "$ID")

        _sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | _sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        
        _sudo wget -qO- "https://download.docker.com/linux/${os_id}/gpg" | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${os_id} ${codename} stable" | _sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

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
    echo "📦 Installing packages..."

    case "$PM" in
        "brew") 
            brew install "${common_pkgs[@]}" fd eza bat
            ln -sf "$(brew --prefix)/bin/eza" "$HOME/bin/eza"
            ln -sf "$(brew --prefix)/bin/bat" "$HOME/bin/bat"
            ln -sf "$(brew --prefix)/bin/fd" "$HOME/bin/fd"
            ;;
        "apt") _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza bat || true ;;
        "dnf") _sudo dnf install -y -q "${common_pkgs[@]}" fd-find eza bat || true ;;
    esac

    # OSパッケージ版のシンボリックリンク作成
    [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"

    local arch; arch=$(uname -m)
    local os_type="unknown-linux-gnu"
    [[ "$OSTYPE" == "darwin"* ]] && os_type="apple-darwin"

    # --- eza ダウンロード ---
    if ! command -v eza >/dev/null 2>&1; then
        echo "⬇️ Downloading eza binary..."
        local eza_urls=("https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-${os_type}.tar.gz" "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz")
        for url in "${eza_urls[@]}"; do
            if curl -fLsS "$url" | tar xz -C "$HOME/bin" 2>/dev/null; then
                find "$HOME/bin" -type f -name "eza*" ! -name "*.gz" -exec mv {} "$HOME/bin/eza" \;
                chmod +x "$HOME/bin/eza" && break
            fi
        done
    fi

    # --- bat ダウンロード ---
    if ! command -v bat >/dev/null 2>&1 && [ "$PM" != "brew" ]; then
        echo "⬇️ Downloading bat binary..."
        local bat_v="v0.24.0"
        local bat_os="unknown-linux-musl"
        [[ "$os_type" == "apple-darwin" ]] && bat_os="apple-darwin"
        curl -fLsS "https://github.com/sharkdp/bat/releases/download/${bat_v}/bat-${bat_v}-${arch}-${bat_os}.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null
        find "$HOME/bin" -type f -name "bat" ! -name "*.gz" -exec mv {} "$HOME/bin/bat" \;
        chmod +x "$HOME/bin/bat"
    fi

    # --- fd ダウンロード ---
    if ! command -v fd >/dev/null 2>&1 && [ "$PM" != "brew" ]; then
        echo "⬇️ Downloading fd binary..."
        local fd_v="v10.2.0"
        local fd_os="unknown-linux-musl"
        [[ "$os_type" == "apple-darwin" ]] && fd_os="apple-darwin"
        curl -fLsS "https://github.com/sharkdp/fd/releases/download/${fd_v}/fd-${fd_v}-${arch}-${fd_os}.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null
        find "$HOME/bin" -type f -name "fd" ! -name "*.gz" -exec mv {} "$HOME/bin/fd" \;
        chmod +x "$HOME/bin/fd"
    fi
}

setup_oh_my_zsh() {
    [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    local custom_dir="$HOME/.oh-my-zsh/custom"
    mkdir -p "$custom_dir/themes" "$custom_dir/plugins"
    [ -d "$DOTPATH/zsh/themes/powerlevel10k" ] && ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$custom_dir/themes/powerlevel10k"
    for p in zsh-autosuggestions zsh-syntax-highlighting history-search-multi-word; do
        [ -d "$DOTPATH/zsh/plugins/$p" ] && ln -sfn "$DOTPATH/zsh/plugins/$p" "$custom_dir/plugins/$p"
    done
}

setup_ai_tools() {
    command -v llm >/dev/null 2>&1 || { pipx install llm && pipx inject llm llm-gemini; }
    cat << 'EOF' > "$HOME/bin/ginv"
#!/bin/bash
[ -z "$1" ] && exit 1
llm -m gemini-2.0-flash "$1"
EOF
    chmod +x "$HOME/bin/ginv"
}

deploy_configs() {
    safe_replace() { perl -pe "s|__DOTPATH__|$DOTPATH|g" "$1" > "$2"; }
    safe_replace "$DOTPATH/zsh/.zshrc" "$1/.zshrc"
    safe_replace "$DOTPATH/bash/.bashrc" "$1/.bashrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$1/.gitconfig"
}

setup_root_loader() {
    _sudo bash -c "cat << 'EOF' > /root/.bashrc_rafale
export DOTPATH='$DOTPATH'
[ -f \"\$DOTPATH/common/loader.sh\" ] && . \"\$DOTPATH/common/loader.sh\"
EOF"
    _sudo bash -c "grep -q '.bashrc_rafale' /root/.bashrc || echo 'source /root/.bashrc_rafale' >> /root/.bashrc"
}
