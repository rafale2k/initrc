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
    if command -v apk >/dev/null 2>&1; then
        _sudo apk add --no-cache "${common_pkgs[@]}" fd eza bat-extras || true
    elif command -v brew >/dev/null 2>&1; then
        brew install "${common_pkgs[@]}" fd eza bat || true
    elif command -v apt-get >/dev/null 2>&1; then
        _sudo apt-get update -qq || true
        # Ubuntu/Debian は batcat, fdfind という名前
        _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find bat || true
    elif command -v dnf >/dev/null 2>&1; then
        # AlmaLinux 等で epel-release が必要な場合への配慮
        _sudo dnf install -y -q epel-release || true
        _sudo dnf install -y -q --allowerasing "${common_pkgs[@]}" fd-find bat || true
    fi

    # 2. 名前の正規化 (batcat -> bat, fdfind -> fd)
    # パッケージマネージャーで入った実体を探して $HOME/bin にリンク
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

    # 3. 最終救済: それでも bat/fd が無いならバイナリを落とす
    local arch; arch=$(uname -m)
    local os_type; os_type=$(uname -s)

    # eza (これは今のままでOK)
    if ! command -v eza >/dev/null 2>&1 && [ ! -f "$HOME/bin/eza" ]; then
        local e_os="unknown-linux-gnu"
        [ "$os_type" = "Darwin" ] && e_os="apple-darwin"
        curl -fLsS "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-${e_os}.tar.gz" | tar xz -C "$HOME/bin" 2>/dev/null || true
        find "$HOME/bin" -type f -name "eza*" ! -name "*.gz" -exec mv {} "$HOME/bin/eza" \; 2>/dev/null || true
        chmod +x "$HOME/bin/eza"
    fi

    # bat 救済 (Linuxのみ)
    if [ "$os_type" = "Linux" ] && ! command -v bat >/dev/null 2>&1 && [ ! -f "$HOME/bin/bat" ]; then
        echo "⬇️ Downloading latest bat binary..."
        local bat_ver; bat_ver=$(curl -fLsS -o /dev/null -w "%{url_effective}" https://github.com/sharkdp/bat/releases/latest | awk -F/ '{print $NF}')
        if [ -n "$bat_ver" ]; then
            curl -fLsS "https://github.com/sharkdp/bat/releases/download/${bat_ver}/bat-${bat_ver}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 2>/dev/null || true
            chmod +x "$HOME/bin/bat"
        fi
    fi

    # fd 救済 (Linuxのみ)
    if [ "$os_type" = "Linux" ] && ! command -v fd >/dev/null 2>&1 && [ ! -f "$HOME/bin/fd" ]; then
        echo "⬇️ Downloading latest fd binary..."
        local fd_ver; fd_ver=$(curl -fLsS -o /dev/null -w "%{url_effective}" https://github.com/sharkdp/fd/releases/latest | awk -F/ '{print $NF}')
        if [ -n "$fd_ver" ]; then
            curl -fLsS "https://github.com/sharkdp/fd/releases/download/${fd_ver}/fd-${fd_ver}-${arch}-unknown-linux-musl.tar.gz" | tar xz -C "$HOME/bin" --strip-components=1 2>/dev/null || true
            chmod +x "$HOME/bin/fd"
        fi
    fi
}

setup_oh_my_zsh() {
    # DOTPATH が未定義なら、このスクリプトがある場所を基準にする（一例）
    : "${DOTPATH:=$HOME/dotfiles}"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "インストール中..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local custom_dir="$HOME/.oh-my-zsh/custom"
    mkdir -p "$custom_dir/themes" "$custom_dir/plugins"

    # powerlevel10k のリンク
    if [ -d "$DOTPATH/zsh/themes/powerlevel10k" ]; then
        ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$custom_dir/themes/powerlevel10k"
    fi

    echo "🔗 Linking Zsh plugins..."
    for p in zsh-autosuggestions zsh-syntax-highlighting history-search-multi-word; do
        if [ -d "$DOTPATH/zsh/plugins/$p" ]; then
            ln -sfn "$DOTPATH/zsh/plugins/$p" "$custom_dir/plugins/$p"
            echo "✅ Linked $p"
        else
            echo "❌ Plugin not found in $DOTPATH/zsh/plugins/$p"
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

verify_installation() {
    local EXIT_CODE=0
    echo "--- Checking Modern CLI Tools ---"

    check_tool() {
        local cmd=$1
        local alt_name=${2:-""}

        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✅ $cmd found at $(command -v "$cmd")"
            "$cmd" --version 2>/dev/null | head -n 1 || echo "Version: N/A"
        elif [[ -n "$alt_name" ]] && command -v "$alt_name" >/dev/null 2>&1; then
            echo "✅ $alt_name found, using as $cmd (OS-specific name)"
        else
            echo "❌ $cmd (or $alt_name) not found in PATH."
            echo "💡 Hint: Ensure your PATH includes /usr/local/bin or ~/bin"
            return 1
        fi
    }

    # 1. ツールチェック
    check_tool "eza" "exa" || EXIT_CODE=1
    check_tool "bat" "batcat" || EXIT_CODE=1
    check_tool "fd" "fdfind" || EXIT_CODE=1

    echo "--- Checking AI Wrappers ---"
    local TARGET_BIN_DIR="${HOME}/bin"
    if [[ -f "$TARGET_BIN_DIR/ginv" ]]; then
        echo "✅ ginv found at $TARGET_BIN_DIR/ginv"
    else
        echo "⚠️  ginv not found at $TARGET_BIN_DIR/ginv."
        # ginv is optional/generated, so maybe just warn? Or fail if critical.
        # Keeping it as a warning for now based on original script, but original script didn't exit on it?
        # Actually original script said "One or more critical tools are missing" if EXIT_CODE!=0.
        # ginv check didn't set EXIT_CODE in the original script.
    fi

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "------------------------------------------------"
        echo "🚨 Error: One or more critical tools are missing."
        echo "Please install dependencies before proceeding."
        echo "------------------------------------------------"
        return 1
    fi
    return 0
}
