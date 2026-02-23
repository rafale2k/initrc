#!/bin/bash

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# 外部関数の読み込み
if [ -f "$DOTPATH/common/install_functions.sh" ]; then
    source "$DOTPATH/common/install_functions.sh"
else
    echo "❌ Error: common/install_functions.sh not found."
    exit 1
fi

# ---------------------------------------------------------
# 0. GitHub SSH 接続テスト
# ---------------------------------------------------------
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new >/dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "✅ GitHub SSH connection successful."
else
    echo "⚠️  GitHub SSH connection failed. Continuing anyway..."
fi

# ---------------------------------------------------------
# 1. OS判別 & パッケージマネージャー設定
# ---------------------------------------------------------
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"; PM="brew"; SUDO_CMD=""
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"; SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
else
    OS="unknown"; PM="none"; SUDO_CMD=""
fi

echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. パス情報の保存
# ---------------------------------------------------------
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$PATH"
EOF
chmod 644 "$HOME/.dotfiles_env"
export PATH="$DOTPATH/bin:$PATH"

# ---------------------------------------------------------
# 3. OS初期セットアップ (Update & リポジトリ)
# ---------------------------------------------------------
setup_os "$PM" "$SUDO_CMD"

# ---------------------------------------------------------
# 4. モダンツールの自動インストール
# ---------------------------------------------------------
# git-extras と docker を追加
REQUIRED_TOOLS=("tree" "git" "git-extras" "docker" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget")
echo "🛠️  Installing required tools..."

for tool in "${REQUIRED_TOOLS[@]}"; do
    # git-extras のようなハイフン入りコマンドは特殊判定が必要な場合があるが基本これでOK
    if ! command -v "$tool" &> /dev/null && ! command -v "${tool}cat" &> /dev/null && ! command -v "${tool}find" &> /dev/null; then
        echo "🎁 $tool is missing. Installing..."
        # 関数名として有効な形式（ハイフンをアンダースコアに置換）に変換して確認
        func_name="install_${tool//-/_}"
        if declare -f "$func_name" > /dev/null; then
            "$func_name" "$PM" "$DOTPATH" "$SUDO_CMD"
        else
            $SUDO_CMD $PM install -y "$tool"
        fi
    else
        echo "✅ $tool is already installed."
    fi
done

# ---------------------------------------------------------
# 5. Zsh / Oh My Zsh & Plugins Setup (上書き対策版)
# ---------------------------------------------------------
echo "🐚 Setting up Zsh and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "🔗 Enforcement linking Zsh configs (p10k protection)..."
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
mkdir -p "${ZSH_CUSTOM}/plugins"

if [ -d "$DOTPATH/zsh/plugins" ]; then
    for plugin_path in "$DOTPATH"/zsh/plugins/*; do
        name=$(basename "$plugin_path")
        if [ -d "$plugin_path" ]; then
            echo "🔗 Linking Zsh plugin: $name"
            ln -sf "$plugin_path" "${ZSH_CUSTOM}/plugins/${name}"
        fi
    done
fi

# ---------------------------------------------------------
# 6. シンボリックリンク & 設定ファイル生成
# ---------------------------------------------------------
echo "🔗 Creating symbolic links from configs/..."
if [ -d "$DOTPATH/configs" ]; then
    for config_file in "$DOTPATH"/configs/*; do
        filename=$(basename "$config_file")
        target="$HOME/.$filename"

        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "📦 Backing up $target to ${target}.bak"
            mv "$target" "${target}.bak"
        fi

        if [ "$filename" == "nanorc" ]; then
            echo "📝 Generating $target (Path substitution)..."
            sed "s|__DOTPATH__|$DOTPATH|g" "$config_file" > "$target"
        elif [ "$filename" == "gitconfig" ]; then
            echo "✅ Linking gitconfig -> $target"
            ln -sf "$config_file" "$target"

            GIT_LOCAL="$HOME/.gitconfig.local"
            if [ ! -f "$GIT_LOCAL" ]; then
                echo "👤 Git local settings not found. Let's set up your identity."
                curr_name=$(git config --global user.name || echo "Dassault Rafale")
                curr_email=$(git config --global user.email || echo "d.rafale@gmail.com")
                
                read -p "Enter Git User Name [$curr_name]: " git_name
                git_name=${git_name:-$curr_name}
                read -p "Enter Git User Email [$curr_email]: " git_email
                git_email=${git_email:-$curr_email}

                cat << EOF > "$GIT_LOCAL"
[user]
	name = $git_name
	email = $git_email
EOF
                echo "✅ Created $GIT_LOCAL"
            fi
        else
            ln -sf "$config_file" "$target"
        fi
    done
fi

mkdir -p "$HOME/.nano"
ln -sf "$DOTPATH/editors/my-themes/monokai.nanorc" "$HOME/.nano/monokai.nanorc"

# ---------------------------------------------------------
# 7. ローカルテンプレート作成
# ---------------------------------------------------------
[ -f "$DOTPATH/common/.env" ] && [ ! -f "$DOTPATH/common/.env.local" ] && cp "$DOTPATH/common/.env" "$DOTPATH/common/.env.local"

# ---------------------------------------------------------
# 8. 最終確定 & パレット適用
# ---------------------------------------------------------
echo "🔐 Finalizing permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH" 2>/dev/null || true
chmod +x "$DOTPATH/bin/"* 2>/dev/null || true

if [ -f "$DOTPATH/bin/monokai-palette.sh" ]; then
    echo "🎨 Applying Monokai palette..."
    bash "$DOTPATH/bin/monokai-palette.sh"
fi

source "$HOME/.dotfiles_env"

echo "✨ All Done! Please restart your shell or run: exec zsh -l"
