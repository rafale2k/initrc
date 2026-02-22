#!/bin/bash

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# ---------------------------------------------------------
# 1. OS判別とパッケージマネージャーの設定
# ---------------------------------------------------------
if [ "$(uname)" = "Darwin" ]; then
    OS="mac"; PM="brew"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"; PM="dnf"
elif [ -f /etc/debian_version ]; then
    OS="debian"; PM="apt"
else
    OS="unknown"
fi

echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. パス情報の保存 (loader.sh の生命線)
# ---------------------------------------------------------
echo "export DOTFILES_PATH=\"$DOTPATH\"" > "$HOME/.dotfiles_env"
SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")

# root環境用 (sudo が利用可能な場合)
if [ -n "$SUDO_CMD" ]; then
    $SUDO_CMD sh -c "echo \"export DOTFILES_PATH=\\\"$DOTPATH\\\"\" > /root/.dotfiles_env"
else
    [ "$EUID" -eq 0 ] && echo "export DOTFILES_PATH=\"$DOTPATH\"" > /root/.dotfiles_env
fi

# ---------------------------------------------------------
# 3. モダンツールの自動インストール
# ---------------------------------------------------------
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq")
echo "🛠️  Checking required tools..."

case "$PM" in
    "apt") $SUDO_CMD apt update -y ;;
    "dnf") $SUDO_CMD dnf install -y epel-release ;;
esac

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null && ! command -v "${tool}cat" &> /dev/null && ! command -v "${tool}find" &> /dev/null; then
        echo "🎁 $tool is missing. Installing..."
        case "$PM" in
            "brew") brew install "$tool" ;;
            "apt")
                pkg="$tool"
                [ "$tool" = "fd" ] && pkg="fd-find"
                if [ "$tool" = "eza" ]; then
                    $SUDO_CMD mkdir -p /etc/apt/keyrings
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO_CMD tee /etc/apt/sources.list.d/gierens.list
                    $SUDO_CMD apt update
                fi
                $SUDO_CMD apt install -y "$pkg"
                ;;
            "dnf") $SUDO_CMD dnf install -y "$tool" ;;
        esac
    else
        echo "✅ $tool is already installed."
    fi
done

# ---------------------------------------------------------
# 4. シンボリックリンク作成 (物理配置に完全一致)
# ---------------------------------------------------------
echo "🔗 Creating symbolic links..."

# --- Zsh (User) ---
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# --- Common (User) ---
ln -sf "$DOTPATH/common/gitignore_global" "$HOME/.gitignore_global"
[ -f "$DOTPATH/common/inputrc" ] && ln -sf "$DOTPATH/common/inputrc" "$HOME/.inputrc"

# --- Editors (User) ---
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"

# --- Root (Bash/Vim/Common) ---
if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    $SUDO_CMD ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
    $SUDO_CMD ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
    $SUDO_CMD ln -sf "$DOTPATH/common/gitignore_global" "/root/.gitignore_global"
    [ -f "$DOTPATH/common/inputrc" ] && $SUDO_CMD ln -sf "$DOTPATH/common/inputrc" "/root/.inputrc"
fi

# ---------------------------------------------------------
# 5. Git Setup (テンプレート分離ロジック)
# ---------------------------------------------------------
echo "📝 Setting up Git..."
if [ ! -f "$HOME/.gitconfig" ]; then
    # 実体がない場合のみ、共通設定をインクルードする設定ファイルを作成
    cat << EOF > "$HOME/.gitconfig"
[user]
	name = Dassult Rafale
	email = d.rafale@gmail.com
[include]
	path = $DOTPATH/common/gitconfig
EOF
    echo "✅ Created new ~/.gitconfig with include."
else
    # すでに実体がある場合は、include設定がなければ追記する（安全策）
    if ! grep -q "path = $DOTPATH/common/gitconfig" "$HOME/.gitconfig"; then
        echo -e "[include]\n\tpath = $DOTPATH/common/gitconfig" >> "$HOME/.gitconfig"
        echo "➕ Added include path to existing ~/.gitconfig."
    fi
fi

# ---------------------------------------------------------
# 6. Nano Syntax Highlighting & .nanorc
# ---------------------------------------------------------
echo "📝 Setting up Nano..."
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi

if [ -f "$DOTPATH/editors/.nanorc" ]; then
    # パスを動的置換して配置
    sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"
    [ -n "$SUDO_CMD" ] && $SUDO_CMD cp "$HOME/.nanorc" "/root/.nanorc"
fi

# ---------------------------------------------------------
# 7. 最終調整 (権限など)
# ---------------------------------------------------------
echo "🔐 Adjusting permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod 755 "$DOTPATH"
chmod 644 "$HOME/.dotfiles_env"

echo "✨ All Done! Modular Dotfiles are now active."
echo "👉 Run 'source ~/.zshrc' to refresh your current session."
