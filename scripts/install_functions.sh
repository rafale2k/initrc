#!/bin/bash

# shellcheck disable=SC1091
_sudo() {
    if [ -z "${SUDO_CMD:-}" ]; then "$@"; else $SUDO_CMD "$@"; fi
}

setup_os_repos() {
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring apt repositories..."
        # SC2015 対策: 分割して確実に実行
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release xz-utils || true

        # 変数をちゃんと使う（SC2034 対策）
        local os_id; os_id=$(. /etc/os-release; echo "$ID")
        local codename; codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2 | tr -d '"')

        _sudo mkdir -p /etc/apt/keyrings

        # eza: 2026年現在、より確実なリポジトリ構成
        if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | _sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        fi

        # Docker: 取得した os_id と codename をここで使い切る！
        if wget -qO- "https://download.docker.com/linux/${os_id}/gpg" | _sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${os_id} ${codename} stable" | _sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        
        # リポジトリ追加後は update が必須！
        _sudo apt-get update -qq || true

    elif [ "$PM" = "dnf" ]; then
        echo "⚙️  Configuring dnf repositories..."
        # AlmaLinux / RHEL 系なら EPEL は必須
        _sudo dnf install -y -q epel-release || true
        _sudo dnf makecache -q || true
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras)
    mkdir -p "$HOME/bin"
    
    echo "📦 Starting Package Installation..."

    # 1. パッケージマネージャー別の処理（Alpine対応を一番上に追加）
    if command -v apk >/dev/null 2>&1; then
        echo "🏔️  Alpine detected."
        _sudo apk add --no-cache "${common_pkgs[@]}" fd eza bat-extras || true
    elif command -v brew >/dev/null 2>&1; then
        brew install "${common_pkgs[@]}" fd eza bat || true
    elif command -v apt-get >/dev/null 2>&1; then
        _sudo apt-get update -qq || true
        _sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find bat eza || true
    elif command -v dnf >/dev/null 2>&1; then
        _sudo dnf install -y -q --allowerasing "${common_pkgs[@]}" fd-find bat eza || true
    fi

    # 2. 名前の正規化（ここが賢さの源泉！）
    echo "🔗 Linking binaries..."
    # bat
    [ -n "$(command -v batcat)" ] && ln -sf "$(command -v batcat)" "$HOME/bin/bat"
    [ -n "$(command -v bat)" ] && ln -sf "$(command -v bat)" "$HOME/bin/bat"
    # fd
    [ -n "$(command -v fdfind)" ] && ln -sf "$(command -v fdfind)" "$HOME/bin/fd"
    [ -n "$(command -v fd)" ] && ln -sf "$(command -v fd)" "$HOME/bin/fd"
    # eza
    [ -n "$(command -v eza)" ] && ln -sf "$(command -v eza)" "$HOME/bin/eza"
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
