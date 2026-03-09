#!/bin/bash

_sudo() {
    if [ -z "${SUDO_CMD:-}" ]; then "$@"; else $SUDO_CMD "$@"; fi
}

setup_os_repos() {
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring apt..."
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release || true
        
        # SC2034 対策: codename をリポジトリ登録で適切に使用
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')
        
        _sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | _sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        
        # Docker 用に codename を使用
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | _sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || true

    elif [ "$PM" = "dnf" ]; then
        # SC2015 対策: A && B || C を使わず if 文で明確に
        if [ "$OS" = "rhel" ]; then
            _sudo dnf install -y -q epel-release || true
        fi
        _sudo dnf makecache -q || true
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras)
    mkdir -p "$HOME/bin"
    echo "📦 Installing packages..."

    case "$PM" in
        "brew") brew install "${common_pkgs[@]}" fd eza bat ;;
        "apt") _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza bat || true ;;
        "dnf") _sudo dnf install -y -q "${common_pkgs[@]}" fd-find eza bat || true ;;
    esac

    [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
    [ -f /usr/bin/fd-find ] && [ ! -f "$HOME/bin/fd" ] && ln -sf /usr/bin/fd-find "$HOME/bin/fd"

    if ! command -v git-summary >/dev/null 2>&1; then
        echo "⚠️  git-extras not found. Building from source..."
        (cd /tmp && git clone --depth 1 https://github.com/tj/git-extras.git && cd git-extras && _sudo make install)
    fi

    local arch; arch=$(uname -m)
    if ! command -v eza >/dev/null 2>&1; then
        curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null || true
    fi
    if ! command -v bat >/dev/null 2>&1 && [ "$PM" != "brew" ]; then
        local bat_v="v0.24.0"
        curl -L "https://github.com/sharkdp/bat/releases/download/${bat_v}/bat-${bat_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 "bat-${bat_v}-${arch}-unknown-linux-musl/bat" 2>/dev/null || true
    fi
    if ! command -v fd >/dev/null 2>&1 && [ "$PM" != "brew" ]; then
        local fd_v="v10.2.0"
        curl -L "https://github.com/sharkdp/fd/releases/download/${fd_v}/fd-${fd_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 "fd-${fd_v}-${arch}-unknown-linux-musl/fd" 2>/dev/null || true
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
