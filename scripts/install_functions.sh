#!/bin/bash

# --- Technical Standards ---
# Final robust cross-distro installer.
# Fixes SC2086, SC2034, and adds full binary fallback for fd/bat/eza.

_sudo() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@"
    fi
}

setup_os_repos() {
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "${DOTPATH:-}" ] && DOTPATH="$dotpath_tmp"
    
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring apt repositories..."
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release || true
        
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')
        
        _sudo mkdir -p /etc/apt/keyrings
        
        # Eza repo
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
            _sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
            _sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        
        # Docker repo
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            _sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | \
            _sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        _sudo apt-get update -qq || true
        
    elif [ "$PM" = "dnf" ]; then
        echo "⚙️  Configuring dnf repositories..."
        if grep -qi "Alma" /etc/os-release 2>/dev/null; then
            echo "  📦 Enabling EPEL for AlmaLinux..."
            _sudo dnf install -y -q epel-release || true
        fi
        _sudo dnf makecache -q || true
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx)
    mkdir -p "$HOME/bin"
    export PATH="$HOME/bin:$PATH"

    if [ "$OS" = "mac" ]; then
        brew install "${common_pkgs[@]}" fd eza bat
    else
        if [ "$PM" = "apt" ]; then
            _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza bat || true
        elif [ "$PM" = "dnf" ]; then
            _sudo dnf install -y -q "${common_pkgs[@]}" fd-find eza bat || true
        fi
    fi

    # --- Naming Normalization ---
    [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
    # DNFでfd-findとして入った場合のリンク
    [ -f /usr/bin/fd-find ] && [ ! -f "$HOME/bin/fd" ] && ln -sf /usr/bin/fd-find "$HOME/bin/fd"

    # --- FALLBACK: eza ---
    if ! command -v eza >/dev/null 2>&1; then
        echo "⚠️  eza missing. Downloading binary..."
        local arch
        arch=$(uname -m)
        curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null || true
        chmod +x "$HOME/bin/eza" 2>/dev/null || true
    fi

    # --- FALLBACK: bat (Fixed SC2086) ---
    if ! command -v bat >/dev/null 2>&1; then
        echo "⚠️  bat missing. Downloading binary..."
        local arch bat_v="v0.24.0"
        arch=$(uname -m)
        curl -L "https://github.com/sharkdp/bat/releases/download/${bat_v}/bat-${bat_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C /tmp/ 2>/dev/null || true
        mv "/tmp/bat-${bat_v}-${arch}-unknown-linux-musl/bat" "$HOME/bin/bat" 2>/dev/null || true
        chmod +x "$HOME/bin/bat"
    fi

    # --- FALLBACK: fd (AlmaLinux/DNF workaround) ---
    if ! command -v fd >/dev/null 2>&1; then
        echo "⚠️  fd missing. Downloading binary..."
        local arch fd_v="v10.2.0"
        arch=$(uname -m)
        curl -L "https://github.com/sharkdp/fd/releases/download/${fd_v}/fd-${fd_v}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C /tmp/ 2>/dev/null || true
        mv "/tmp/fd-${fd_v}-${arch}-unknown-linux-musl/fd" "$HOME/bin/fd" 2>/dev/null || true
        chmod +x "$HOME/bin/fd"
    fi
}

setup_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local custom_plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$custom_plugin_dir"

    # サブモジュールの実体があるパス
    local sub_src="$DOTPATH/zsh/plugins"

    # 指定したプラグインをリンクする関数
    link_plugin() {
        local name=$1
        if [ -d "$sub_src/$name" ]; then
            echo "🔗 Linking $name..."
            ln -sfn "$sub_src/$name" "$custom_plugin_dir/$name"
        else
            # 実体がないのに読み込もうとするとエラーが出るので警告
            echo "⚠️  Warning: Submodule $name not found in $sub_src"
        fi
    }

    # 必要なプラグインを全部リンク
    link_plugin "zsh-autosuggestions"
    link_plugin "zsh-syntax-highlighting"
    link_plugin "history-search-multi-word"
}

setup_ai_tools() {
    export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm || true
        pipx inject llm llm-gemini || true
    fi
    local ginv_path="$HOME/bin/ginv"
    mkdir -p "$(dirname "$ginv_path")"
    cat << 'EOF' > "$ginv_path"
#!/bin/bash
if [ -z "$1" ]; then exit 1; fi
llm -m gemini-2.5-flash "$1"
EOF
    chmod +x "$ginv_path"
}

deploy_configs() {
    local target_home="${1:-$HOME}"
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "$DOTPATH" ] && DOTPATH="$dotpath_tmp"

    mkdir -p "$target_home/.dotfiles_backup"
    
    safe_replace() {
        local src="$1" dst="$2"
        [ ! -f "$src" ] && return 0
        [ -L "$dst" ] && rm "$dst"
        perl -pe "s|__DOTPATH__|$DOTPATH|g" "$src" > "$dst"
    }

    safe_replace "$DOTPATH/zsh/.zshrc" "$target_home/.zshrc"
    safe_replace "$DOTPATH/bash/.bashrc" "$target_home/.bashrc"
    ln -sf "$DOTPATH/configs/gitconfig" "$target_home/.gitconfig"
}

setup_root_loader() {
    local t="${1:-$HOME}"
    local loader_line="source '$DOTPATH/common/loader.sh'"
    for f in "$t/.zshrc" "$t/.bashrc"; do
        if [ -f "$f" ]; then
            perl -i -pe "s|common/loader\.sh|common/already_loaded.txt|g" "$f"
            echo -e "\n$loader_line # MAIN_LOADER" >> "$f"
        fi
    done
}

deploy_local_configs() {
    return 0
}
