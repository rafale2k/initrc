#!/bin/bash
DOTPATH=$(cd $(dirname $0); pwd)

# --- GitHub SSH 接続チェック ---
echo "Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"

if [ $? -ne 0 ]; then
    echo "❌ Error: GitHub SSH authentication failed."
    echo "Please ensure your SSH public key is registered on GitHub."
    echo "Your public key (~/.ssh/id_ed25519.pub):"
    cat ~/.ssh/id_ed25519.pub || echo "(Key not found)"
    exit 1
else
    echo "✅ GitHub SSH connection: OK"
fi

if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key not found. Generating one..."
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

# --- 基本ツールの自動インストール ---
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze")

echo "Checking required tools..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Installing $tool..."
        if [ "$EUID" -ne 0 ]; then
            sudo apt update && sudo apt install -y "$tool"
        else
            apt update && apt install -y "$tool"
        fi
    else
        echo "✅ $tool is already installed."
    fi
done

# bat (batcat) の特殊チェック
if ! command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    echo "Installing bat..."
    SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
    $SUDO_CMD apt install -y bat
else
    echo "✅ bat is already installed."
fi

# --- シンボリックリンク作成 ---
echo "Creating symbolic links..."

# User Links
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTPATH/editors/.nanorc" "$HOME/.nanorc"
ln -sf "$DOTPATH/common/.inputrc" "$HOME/.inputrc" # 追加

# Root Links
sudo ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
sudo ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
sudo ln -sf "$DOTPATH/editors/.nanorc" "/root/.nanorc"
sudo ln -sf "$DOTPATH/common/.inputrc" "/root/.inputrc" # 追加

# --- Nano Syntax Highlighting ---
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi

# --- rootユーザーへの設定反映 (common_aliases.sh) ---
echo "Setting up common_aliases for root user..."

COMMON_PATH="$DOTPATH/common/common_aliases.sh"
LOAD_STR="[[ -f $COMMON_PATH ]] && source $COMMON_PATH"
ROOT_CONFIGS=("/root/.bashrc" "/root/.zshrc")

for config in "${ROOT_CONFIGS[@]}"; do
    if sudo [ -f "$config" ]; then
        if ! sudo grep -q "common_aliases.sh" "$config"; then
            echo "Adding source to $config"
            echo "$LOAD_STR" | sudo tee -a "$config" > /dev/null
        else
            echo "✅ Already set in $config"
        fi
    fi
done

# --- 権限調整 ---
# rootが一般ユーザーのディレクトリ内のファイルを読み込めるようにする
chmod 755 "$HOME"
chmod 755 "$DOTPATH"
chmod 755 "$DOTPATH/common"
chmod 644 "$COMMON_PATH"
chmod 644 "$DOTPATH/common/.inputrc"

echo "✨ Setup complete. Everything is linked and root environment is ready!"
