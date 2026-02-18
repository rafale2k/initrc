#!/bin/bash
DOTPATH=$(cd $(dirname $0); pwd)

# --- GitHub SSH 接続チェック ---
echo "Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"

if [ $? -ne 0 ]; then
    echo "❌ Error: GitHub SSH authentication failed."
    echo "Your public key (~/.ssh/id_ed25519.pub):"
    cat ~/.ssh/id_ed25519.pub || echo "(Key not found)"
    # ここで exit 1 するかはお好みやけど、とりあえず続行するようにしとくで
else
    echo "✅ GitHub SSH connection: OK"
fi

# --- 基本ツールの自動インストール ---
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze" "sudo")
echo "Checking required tools..."

# 最初に一回だけ update
SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
$SUDO_CMD apt update -y

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Installing $tool..."
        $SUDO_CMD apt install -y "$tool"
    else
        echo "✅ $tool is already installed."
    fi
done

# bat (batcat) の特殊チェック
if ! command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    echo "Installing bat..."
    $SUDO_CMD apt install -y bat
fi

# --- シンボリックリンク作成 ---
echo "Creating symbolic links..."

# User Links
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTPATH/editors/.nanorc" "$HOME/.nanorc"
ln -sf "$DOTPATH/common/.inputrc" "$HOME/.inputrc"
ln -sf "$DOTPATH/common/gitignore_global" "$HOME/.gitignore_global"

# Root Links (sudo 権限で)
sudo ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
sudo ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
sudo ln -sf "$DOTPATH/editors/.nanorc" "/root/.nanorc"
sudo ln -sf "$DOTPATH/common/.inputrc" "/root/.inputrc"

# --- Nano Syntax Highlighting ---
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    echo "Cloning nano-syntax-highlighting..."
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi

# --- 権限調整 ---
# rootが一般ユーザーのディレクトリ内のファイルを読み込めるようにする
echo "Adjusting permissions..."
chmod 755 "$HOME"
chmod 755 "$DOTPATH"
chmod 755 "$DOTPATH/common"
chmod 644 "$DOTPATH/common/common_aliases.sh"
chmod 644 "$DOTPATH/common/.inputrc"

echo "✨ Setup complete. Everything is linked and root environment is ready!"
echo "Please run 'source ~/.zshrc' to apply changes."
