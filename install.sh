#!/bin/bash
# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# 1. パス情報の保存
echo "export DOTFILES_PATH=\"$DOTPATH\"" > "$HOME/.dotfiles_env"
sudo sh -c "echo \"export DOTFILES_PATH=\\\"$DOTPATH\\\"\" > /root/.dotfiles_env"

# 2. GitHub SSH 接続チェック
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"
if [ $? -ne 0 ]; then
    echo "❌ Error: GitHub SSH authentication failed."
    cat ~/.ssh/id_ed25519.pub || echo "(Key not found)"
else
    echo "✅ GitHub SSH connection: OK"
fi

# 3. 基本ツールの自動インストール
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze" "sudo" "zsh")
echo "🛠️  Checking required tools..."
SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
$SUDO_CMD apt update -y

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Installing $tool..."
        $SUDO_CMD apt install -y "$tool"
    fi
done

# bat (batcat) チェック
if ! command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    $SUDO_CMD apt install -y bat
fi

# 4. シンボリックリンク作成
echo "🔗 Creating symbolic links..."

# User Links
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
ln -sf "$DOTPATH/.inputrc" "$HOME/.inputrc"
ln -sf "$DOTPATH/gitconfig" "$HOME/.gitconfig" # さっき移動したやつ
ln -sf "$DOTPATH/.gitignore_global" "$HOME/.gitignore_global"

# Root Links
sudo ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
sudo ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
sudo ln -sf "$DOTPATH/.inputrc" "/root/.inputrc"
sudo ln -sf "$DOTPATH/gitconfig" "/root/.gitconfig"
sudo ln -sf "$DOTPATH/.gitignore_global" "/root/.gitignore_global"

# 5. Nano Setup (Syntax Highlighting)
echo "📝 Setting up Nano..."
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi
sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"
sudo cp "$HOME/.nanorc" "/root/.nanorc"

# --- 6. Git Config (絶対に include を使わない安全版) ---
echo "⚙️ Configuring Git..."

# ユーザー側の設定をリセットしてリンク
rm -f "$HOME/.gitconfig"
ln -sf "$DOTPATH/gitconfig" "$HOME/.gitconfig"

# root側の設定をリセットしてリンク
sudo rm -f "/root/.gitconfig"
sudo ln -sf "$DOTPATH/gitconfig" "/root/.gitconfig"

# safe.directory の設定（git config コマンドが失敗する可能性を考慮して gitconfig に直接書くか、エラーを無視する）
sudo git config --file "$DOTPATH/gitconfig" --add safe.directory "$DOTPATH" 2>/dev/null || true

# 7. 権限調整
echo "🔐 Adjusting permissions..."
chmod 755 "$HOME"
chmod 755 "$DOTPATH"
chmod -R 755 "$DOTPATH/common"
chmod 644 "$HOME/.dotfiles_env"

echo "✨ Setup complete! Everything is linked."
echo "👉 Run 'source ~/.zshrc' (User) or 'sudo -i' (Root) to enjoy!"
