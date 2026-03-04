#!/bin/bash

# --- OS・パッケージマネージャーの判定とリポジトリ設定 ---
setup_os_repos() {
    local dotpath_tmp
    dotpath_tmp=$(cd "$(dirname "$0")/.." && pwd)
    [ -z "${DOTPATH:-}" ] && DOTPATH="$dotpath_tmp"
    
    if [ "$PM" = "apt" ]; then
        echo "⚙️  Configuring repositories for apt..."
        # 1. 最小限のツールをインストール
        sudo apt-get update -qq --allow-releaseinfo-change || true
        sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release || true
        
        local codename
        codename=$(lsb_release -cs 2>/dev/null || grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2)
        
        # 2. キーリングディレクトリの作成
        sudo mkdir -p /etc/apt/keyrings
        
        # 3. Eza (Exaの後継) のリポジトリ設定
        # --yes を追加して既存の鍵の上書き確認をスキップ
        echo "  🔑 Adding eza key..."
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
            sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
            sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        
        # 4. Docker のリポジトリ設定
        # --yes を追加して既存の鍵の上書き確認をスキップ
        echo "  🐳 Adding docker key..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
            
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # 5. インデックスの最終更新
        sudo apt-get update -qq --allow-releaseinfo-change || true
        
    elif [ "$PM" = "dnf" ]; then
        echo "⚙️  Configuring repositories for dnf..."
        sudo dnf install -y -q epel-release dnf-plugins-core || true
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
        sudo dnf makecache -q || true
    fi
}

install_all_packages() {
    local common_pkgs=(tree git curl vim nano fzf zsh zoxide jq wget pipx git-extras bat)
    if [ "$OS" = "mac" ]; then
        brew install "${common_pkgs[@]}" fd eza docker docker-compose
    elif [ "$PM" = "apt" ]; then
        sudo apt-get install -y -qq "${common_pkgs[@]}" fd-find eza docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
    elif [ "$PM" = "dnf" ]; then
        sudo dnf install -y -q "${common_pkgs[@]}" fd-find docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
    fi
}

setup_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

setup_ai_tools() {
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm || true
        pipx inject llm llm-gemini || true
    fi
    local ginv_path
    ginv_path="$DOTPATH/bin/ginv"
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

    # --- 1. バックアップディレクトリを確実に作成 ---
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$target_home/.dotfiles_backup/$backup_timestamp"
    
    echo "🛡️  Preparing backup: $backup_dir"
    mkdir -p "$backup_dir"

    # --- 2. デプロイ前に既存の実体ファイルをバックアップ ---
    # シンボリックリンクは除外して、実体ファイルだけを安全に退避させる
    local targets=(".zshrc" ".bashrc" ".gitconfig" ".vimrc" ".nanorc" ".inputrc" ".gitignore_global")
    for f_name in "${targets[@]}"; do
        local f_path="$target_home/$f_name"
        if [ -f "$f_path" ] && [ ! -L "$f_path" ]; then
            cp -a "$f_path" "$backup_dir/"
            echo "   📦 Saved original: $f_name"
        fi
    done

    # --- 3. 置換・デプロイ関数 ---
    safe_replace() {
        local src="$1"
        local dst="$2"
        [ ! -f "$src" ] && return 0
        
        # 既存がリンクなら削除（実体ならバックアップ済みなので上書きでOK）
        [ -L "$dst" ] && rm "$dst"
        
        # __DOTPATH__ を現在のパスに置換して配置
        DP="$DOTPATH" perl -pe "s|__DOTPATH__|$DOTPATH|g" "$src" > "$dst"
        echo "   ✅ Deployed: $(basename "$dst")"
    }

    echo "🖇️  Deploying configuration files..."
    
    # テンプレート（.zshrc, .bashrc）のデプロイ
    safe_replace "$DOTPATH/zsh/.zshrc" "$target_home/.zshrc"
    safe_replace "$DOTPATH/bash/.bashrc" "$target_home/.bashrc"
    
    # その他の設定ファイルはシンボリックリンクを貼る
    ln -sf "$DOTPATH/configs/gitconfig" "$target_home/.gitconfig"
    ln -sf "$DOTPATH/configs/vimrc" "$target_home/.vimrc"
    ln -sf "$DOTPATH/configs/inputrc" "$target_home/.inputrc"
    ln -sf "$DOTPATH/configs/gitignore_global" "$target_home/.gitignore_global"

    # --- 4. 環境のリロード ---
    export DOTPATH="$DOTPATH"
    echo "🚀 Environment reloaded."

    # 最後に現在の環境を更新 (変数が未定義でもエラーにならない書き方に変更)
    export DOTPATH="$DOTPATH"
    echo "🚀 Environment reloaded."

    # ${ZSH_VERSION:-} と書くことで、未定義なら空文字として扱いエラーを防ぐ
    if [ -n "${ZSH_VERSION:-}" ]; then
        # shellcheck disable=SC1091
        [ -f "$target_home/.zshrc" ] && source "$target_home/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC1091
        [ -f "$target_home/.bashrc" ] && source "$target_home/.bashrc"
    fi
}

# --- 🔥 重複と構文エラーを物理的に封じ込める ---
setup_root_loader() {
    local t="${1:-$HOME}"
    [ -z "$t" ] || [ "$t" = "/" ] && return 0
    
    local loader_line="source '$DOTPATH/common/loader.sh'"
    
    for f in "$t/.zshrc" "$t/.bashrc"; do
        if [ -f "$f" ]; then
            echo "✨ Purifying $f to resolve duplicates and syntax errors..."
            local tmp_f
            tmp_f="/tmp/purified_rc_$(basename "$f")"
            
            # 1. 「loader.sh」を含む行を「削除」する
            # ただし、一行に source と fi が同居している場合の parse error を防ぐため、
            # 文字列を消すのではなく、loader.sh という単語をダミーの単語に変える。
            # これで grep には引っかからず、構文も維持される。
            sed "s|common/loader\.sh|common/already_loaded.txt|g" "$f" > "$tmp_f"
            
            # 2. ファイルの末尾に「唯一の本物」を追記する
            echo -e "\n$loader_line # MAIN_LOADER" >> "$tmp_f"
            
            mv "$tmp_f" "$f"
        fi
    done
}

deploy_local_configs() {
    local t="$1"
    if [ -d "$DOTPATH/templates" ]; then
        if [ -f "$DOTPATH/templates/.env.example" ] && [ ! -f "$t/.env" ]; then
            cp "$DOTPATH/templates/.env.example" "$t/.env"
        fi
        if [ -f "$DOTPATH/templates/.gitconfig.local.example" ] && [ ! -f "$t/.gitconfig.local" ]; then
            cp "$DOTPATH/templates/.gitconfig.local.example" "$t/.gitconfig.local"
        fi
    fi
    return 0
}
