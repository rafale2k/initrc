#!/bin/bash
#!/bin/bash
# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# 1. パス情報の保存（既存）
echo "export DOTFILES_PATH=\"$DOTPATH\"" > "$HOME/.dotfiles_env"
sudo sh -c "echo \"export DOTFILES_PATH=\\\"$DOTPATH\\\"\" > /root/.dotfiles_env"

# 2. .nanorc の動的生成
# テンプレート内の「DOTFILES_REAL_PATH」を現在の絶対パスに置き換えて配置する
sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"
sudo cp "$HOME/.nanorc" "/root/.nanorc"

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

# --- Nano Setup Section ---
# 1. テンプレート内の DOTFILES_REAL_PATH を現在の絶対パス ($DOTPATH) に置換
# sed の区切り文字に | を使うことで、パスの / と競合させへんのがコツやで！
sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"

# 2. root 用の設定を配る
# 既存のリンクやファイルがあると cp が失敗したり挙動が怪しくなるから、一旦消すのが確実！
sudo rm -f /root/.nanorc
sudo cp "$HOME/.nanorc" "/root/.nanorc"

echo "✨ Nano syntax highlighting paths updated to: $DOTPATH"
# ln -sf "$DOTPATH/editors/monokai.nanorc" "$HOME/.nano/syntax/monokai.nanorc"

# User Links
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"
#ln -sf "$DOTPATH/editors/.nanorc" "$HOME/.nanorc"
ln -sf "$DOTPATH/common/.inputrc" "$HOME/.inputrc"
ln -sf "$DOTPATH/common/gitignore_global" "$HOME/.gitignore_global"

# --- install.sh の Root Links セクション修正 ---
# Root Links (Bash とエディタ、Git 共通設定だけでOK)
sudo ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
sudo ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
#sudo ln -sf "$DOTPATH/editors/.nanorc" "/root/.nanorc"
sudo ln -sf "$DOTPATH/common/.inputrc" "/root/.inputrc"
# Git 設定の本体 (include を効かせるため、shared 本体も root にリンク)
sudo ln -sf "$DOTPATH/common/.gitconfig_shared" "/root/.gitconfig_shared"
sudo ln -sf "$DOTPATH/common/gitignore_global" "/root/.gitignore_global"
# .gitconfig の include 設定
if ! grep -q ".gitconfig_shared" "$HOME/.gitconfig" 2>/dev/null; then
    printf "\n[include]\n    path = ~/.gitconfig_shared\n" >> "$HOME/.gitconfig"
fi

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
chmod 644 "$HOME/.dotfiles_env"

echo "✨ Setup complete. Everything is linked and root environment is ready!"
echo "Please run 'source ~/.zshrc' to apply changes."
