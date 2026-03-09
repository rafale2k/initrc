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
    
    # 【改修】Macでも確実に動くゾンビリンク削除
    # リンク先が存在しないもの、および Mac で悪さをしている /bin/bat へのリンクを物理破壊
    echo "🧹 Purging broken or incorrect symlinks in $HOME/bin..."
    for link in "$HOME/bin"/*; do
        if [ -L "$link" ]; then
            # リンク先が存在しない、またはリンク先が /bin/bat や /bin/fd になっているものを削除
            target=$(readlink "$link")
            if [ ! -e "$link" ] || [[ "$target" == "/bin/bat" ]] || [[ "$target" == "/bin/fd" ]]; then
                rm "$link"
            fi
        fi
    done

    echo "📦 Installing packages via $PM..."
    case "$PM" in
        "brew") 
            brew install "${common_pkgs[@]}" fd eza bat
            local brew_bin; brew_bin=$(brew --prefix)/bin
            # Macはここだけで完結させる
            ln -sfn "${brew_bin}/eza" "$HOME/bin/eza"
            ln -sfn "${brew_bin}/bat" "$HOME/bin/bat"
            ln -sfn "${brew_bin}/fd" "$HOME/bin/fd"
            ;;
        "apt") _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza bat || true ;;
        "dnf") _sudo dnf install -y -q "${common_pkgs[@]}" fd-find eza bat || true ;;
    esac

    # 【改修】Linux判定を完璧に (OSTYPEがlinux*の時のみ実行)
    if [[ "$OSTYPE" == linux* ]]; then
        echo "🐧 Applying Linux-specific symlinks..."
        [ -f /usr/bin/batcat ] && ln -sfn /usr/bin/batcat "$HOME/bin/bat"
        [ -f /usr/bin/fdfind ] && ln -sfn /usr/bin/fdfind "$HOME/bin/fd"
        [ -f /usr/bin/fd-find ] && [ ! -f "$HOME/bin/fd" ] && ln -sfn /usr/bin/fd-find "$HOME/bin/fd"
    fi

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

    # --- bat/fd は Mac(brew) 以外の場合のみフォールバック ---
    if [ "$PM" != "brew" ]; then
        if ! command -v bat >/dev/null 2>&1; then
            echo "⬇️ Downloading bat binary..."
            local bat_v="v0.24.0"
            curl -fLsS "https://github.com/sharkdp/bat/releases/download/${bat_v}/bat-${bat_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null
            find "$HOME/bin" -type f -name "bat" ! -name "*.gz" -exec mv {} "$HOME/bin/bat" \;
            chmod +x "$HOME/bin/bat"
        fi
        if ! command -v fd >/dev/null 2>&1; then
            echo "⬇️ Downloading fd binary..."
            local fd_v="v10.2.0"
            curl -fLsS "https://github.com/sharkdp/fd/releases/download/${fd_v}/fd-${fd_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null
            find "$HOME/bin" -type f -name "fd" ! -name "*.gz" -exec mv {} "$HOME/bin/fd" \;
            chmod +x "$HOME/bin/fd"
        fi
    fi
}

setup_oh_my_zsh() {
    [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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
    ln -sfn "$DOTPATH/configs/gitconfig" "$1/.gitconfig"
}

setup_root_loader() {
    _sudo bash -c "cat << 'EOF' > /root/.bashrc_rafale
export DOTPATH='$DOTPATH'
[ -f \"\$DOTPATH/common/loader.sh\" ] && . \"\$DOTPATH/common/loader.sh\"
EOF"
    _sudo bash -c "grep -q '.bashrc_rafale' /root/.bashrc || echo 'source /root/.bashrc_rafale' >> /root/.bashrc"
}
