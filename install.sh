#!/bin/bash

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# ---------------------------------------------------------
# 1. OS判別とパッケージマネージャーの設定
# ---------------------------------------------------------
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"
    PM="brew"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
    PM="dnf"
elif [ -f /etc/debian_version ]; then
    OS="debian"
    PM="apt"
else
    OS="unknown"
fi

echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. パス情報の保存
# ---------------------------------------------------------
echo "export DOTFILES_PATH=\"$DOTPATH\"" > "$HOME/.dotfiles_env"
sudo sh -c "echo \"export DOTFILES_PATH=\\\"$DOTPATH\\\"\" > /root/.dotfiles_env"

# ---------------------------------------------------------
# 3. GitHub SSH 接続チェック
# ---------------------------------------------------------
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"
if [ $? -ne 0 ]; then
    echo "❌ Error: GitHub SSH authentication failed."
    cat ~/.ssh/id_ed25519.pub || echo "(Key not found)"
else
    echo "✅ GitHub SSH connection: OK"
fi

# ---------------------------------------------------------
# 4. モダンツールの自動インストール
# ---------------------------------------------------------
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze" "sudo" "zsh" "zoxide" "bat" "eza" "fd" "jq")
echo "🛠️  Checking required tools..."

SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")

# パッケージマネージャーのアップデート
case "$PM" in
    "apt") $SUDO_CMD apt update -y ;;
    "dnf") $SUDO_CMD dnf install -y epel-release ;;
esac

for tool in "${REQUIRED_TOOLS[@]}"; do
    # 存在チェック (batcat, fdfind等の別名も考慮)
    if ! command -v "$tool" &> /dev/null && \
       ! command -v "${tool}cat" &> /dev/null && \
       ! command -v "${tool}find" &> /dev/null; then
        
        echo "🎁 $tool is missing. Installing..."

        case "$PM" in
            "brew")
                brew install "$tool"
                ;;
            "apt")
                pkg="$tool"
                [ "$tool" = "bat" ] && pkg="bat"
                [ "$tool" = "fd" ] && pkg="fd-find"
                # eza 用のリポジトリ追加
                if [ "$tool" = "eza" ]; then
                    $SUDO_CMD mkdir -p /etc/apt/keyrings
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/gierens.list
                    $SUDO_CMD apt update
                fi
                $SUDO_CMD apt install -y "$pkg"
                ;;
            "dnf")
                $SUDO_CMD dnf install -y "$tool"
                ;;
        esac
    else
        echo "✅ $tool is already installed."
    fi
done

# ---------------------------------------------------------
# 5. シンボリックリンク作成 (一括)
# ---------------------------------------------------------
echo "🔗 Creating symbolic links..."
# User
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTPATH/.inputrc" "$HOME/.inputrc"
ln -sf "$DOTPATH/gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTPATH/.gitignore_global" "$HOME/.gitignore_global"

# Root
$SUDO_CMD ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
$SUDO_CMD ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
$SUDO_CMD ln -sf "$DOTPATH/.inputrc" "/root/.inputrc"
$SUDO_CMD ln -sf "$DOTPATH/gitconfig" "/root/.gitconfig"
$SUDO_CMD ln -sf "$DOTPATH/.gitignore_global" "/root/.gitignore_global"

# ---------------------------------------------------------
# 6. Nano Setup
# ---------------------------------------------------------
echo "📝 Setting up Nano..."
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi
sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"
$SUDO_CMD cp "$HOME/.nanorc" "/root/.nanorc"

# ---------------------------------------------------------
# 7. 権限調整
# ---------------------------------------------------------
echo "🔐 Adjusting permissions..."
$SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod 755 "$HOME"
chmod 755 "$DOTPATH"
chmod -R 755 "$DOTPATH/common"
chmod 644 "$HOME/.dotfiles_env"

# ---------------------------------------------------------
# 8. Vim Plugin Setup
# ---------------------------------------------------------
echo "📦 Installing Vim plugins..."
vim +PlugInstall +qall
$SUDO_CMD vim +PlugInstall +qall

echo "✨ Setup complete! v1.5.0 Universal Deployer is ready."
echo "👉 Run 'source ~/.zshrc' or 'sudo -i' to enjoy!"
