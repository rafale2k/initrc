#!/bin/bash
# shellcheck disable=SC2148,SC1090,SC1091

setup_os_repos() {
    if [ "$PM" = "apt" ]; then
        log_info "Configuring apt..."
        if _sudo apt-get update -qq; then
            _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release xz-utils || true
        fi
        
        local os_id
        os_id=$(. /etc/os-release; echo "$ID")
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')

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
    
    log_info "Starting Package Installation..."

    # 1. パッケージマネージャーでのインストール
    if command -v apk >/dev/null 2>&1; then
        _sudo apk add --no-cache "${common_pkgs[@]}" fd eza bat-extras || true
    elif command -v brew >/dev/null 2>&1; then
        brew install "${common_pkgs[@]}" fd eza bat || true
    elif command -v apt-get >/dev/null 2>&1; then
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find bat || true
    elif command -v dnf >/dev/null 2>&1; then
        _sudo dnf install -y -q epel-release || true
        _sudo dnf install -y -q --allowerasing "${common_pkgs[@]}" fd-find bat || true
    fi

    # 2. 名前の正規化 (batcat -> bat, fdfind -> fd)
    if [ "$(uname)" = "Linux" ]; then
        if command -v batcat >/dev/null 2>&1; then
            ln -sf "$(command -v batcat)" "$HOME/bin/bat"
        elif command -v bat >/dev/null 2>&1; then
            ln -sf "$(command -v bat)" "$HOME/bin/bat"
        fi
        
        if command -v fdfind >/dev/null 2>&1; then
            ln -sf "$(command -v fdfind)" "$HOME/bin/fd"
        elif command -v fd >/dev/null 2>&1; then
            ln -sf "$(command -v fd)" "$HOME/bin/fd"
        fi
    fi

    # 3. 最終救済
    local arch; arch=$(uname -m)
    local os_type; os_type=$(uname -s)

    if ! command -v eza >/dev/null 2>&1 && [ ! -f "$HOME/bin/eza" ]; then
        local e_os="unknown-linux-gnu"
        [ "$os_type" = "Darwin" ] && e_os="apple-darwin"
        curl -fLsS "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-${e_os}.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null || true
        find "$HOME/bin" -type f -name "eza*" ! -name "*.gz" -exec mv {} "$HOME/bin/eza" \; 2>/dev/null || true
        chmod +x "$HOME/bin/eza"
    fi

    if [ "$os_type" = "Linux" ] && ! command -v bat >/dev/null 2>&1 && [ ! -f "$HOME/bin/bat" ]; then
        log_info "Downloading latest bat binary..."
        local bat_ver; bat_ver=$(curl -fLsS -o /dev/null -w "%{url_effective}" https://github.com/sharkdp/bat/releases/latest | awk -F/ '{print $NF}')
        if [ -n "$bat_ver" ]; then
            curl -fLsS "https://github.com/sharkdp/bat/releases/download/${bat_ver}/bat-${bat_ver}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 2>/dev/null || true
            chmod +x "$HOME/bin/bat"
        fi
    fi

    if [ "$os_type" = "Linux" ] && ! command -v fd >/dev/null 2>&1 && [ ! -f "$HOME/bin/fd" ]; then
        log_info "Downloading latest fd binary..."
        local fd_ver; fd_ver=$(curl -fLsS -o /dev/null -w "%{url_effective}" https://github.com/sharkdp/fd/releases/latest | awk -F/ '{print $NF}')
        if [ -n "$fd_ver" ]; then
            curl -fLsS "https://github.com/sharkdp/fd/releases/download/${fd_ver}/fd-${fd_ver}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 2>/dev/null || true
            chmod +x "$HOME/bin/fd"
        fi
    fi
}
