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
# --- 基本ツールの自動インストール ---
# bat は Ubuntu では batcat という名前なので別で処理
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
    if [ "$EUID" -ne 0 ]; then
        sudo apt install -y bat
    else
        apt install -y bat
    fi
else
    echo "✅ bat is already installed."
fi

# User Links
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTPATH/editors/.nanorc" "$HOME/.nanorc"
# Root Links
sudo ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
sudo ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
sudo ln -sf "$DOTPATH/editors/.nanorc" "/root/.nanorc"
# Syntax Highlighting for Nano
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi
chmod 755 "$HOME" "$DOTPATH"
echo "Setup complete."
