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

# --- rootユーザーの設定ファイルにも共通エイリアスを反映させる ---
DOTFILES_COMMON="$HOME/dotfiles/common/common_aliases.sh"

# rootの.bashrcへの追記
if [ "$EUID" -ne 0 ]; then
    # 一般ユーザー実行時、sudoを使ってrootの.bashrcを書き換える
    sudo bash -c "echo '[[ -f $DOTFILES_COMMON ]] && source $DOTFILES_COMMON' >> /root/.bashrc"
    # rootがzshを使う場合も想定
    sudo bash -c "echo '[[ -f $DOTFILES_COMMON ]] && source $DOTFILES_COMMON' >> /root/.zshrc"
else
    # すでにrootで実行している場合
    echo "[[ -f $DOTFILES_COMMON ]] && source $DOTFILES_COMMON" >> /root/.bashrc
    echo "[[ -f $DOTFILES_COMMON ]] && source $DOTFILES_COMMON" >> /root/.zshrc
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

# ==========================================
# rootユーザーへのエイリアス反映設定
# ==========================================
echo "Setting up aliases for root user..."

# 共通エイリアスファイルの絶対パスを取得
COMMON_PATH="$(realpath ~/dotfiles/common/common_aliases.sh)"
LOAD_STR="[[ -f $COMMON_PATH ]] && source $COMMON_PATH"

# 書き込み対象のリスト
ROOT_CONFIGS=("/root/.bashrc" "/root/.zshrc")

for config in "${ROOT_CONFIGS[@]}"; do
    # root権限で、まだ設定が書かれていない場合のみ追記
    if sudo [ -f "$config" ]; then
        if ! sudo grep -q "common_aliases.sh" "$config"; then
            echo "Adding alias source to $config"
            echo "$LOAD_STR" | sudo tee -a "$config" > /dev/null
        else
            echo "✅ Alias already set in $config"
        fi
    fi
done

# rootがユーザのディレクトリを読み取れるように権限調整
chmod 755 ~/
chmod 755 ~/dotfiles
chmod 755 ~/dotfiles/common
chmod 644 "$COMMON_PATH"

echo "✨ Root user alias setup complete!"

chmod 755 "$HOME" "$DOTPATH"
echo "Setup complete."
