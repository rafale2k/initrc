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
# 2. パス情報の保存 (loader.sh およびコマンド実行の生命線)
# ---------------------------------------------------------
# 一般ユーザー用の環境設定
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
# dotfiles/bin にパスを通す
export PATH="\$DOTFILES_PATH/bin:\$PATH"
EOF

SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")

# root環境用 (sudo が利用可能な場合)
if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    TARGET_ENV="/root/.dotfiles_env"
    $SUDO_CMD sh -c "cat << EOF > $TARGET_ENV
export DOTFILES_PATH=\"$DOTPATH\"
export PATH=\"$DOTPATH/bin:\\\$PATH\"
EOF"
fi

echo "✅ Path to 'bin' directory added to .dotfiles_env"

# ---------------------------------------------------------
# 3. モダンツールの自動インストール
# ---------------------------------------------------------
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget")
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
# 4. Zsh / Oh My Zsh & Plugins Setup (New!)
# ---------------------------------------------------------
echo "🐚 Setting up Zsh and Oh My Zsh..."

# Oh My Zsh 本体 (User)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🎁 Installing Oh My Zsh for $(whoami)..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins (User)
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
PLUGINS_URLS=(
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
)

for item in "${PLUGINS_URLS[@]}"; do
    name=${item%%:*}
    url=${item#*:}
    if [ ! -d "${ZSH_CUSTOM}/plugins/${name}" ]; then
        echo "🔌 Cloning $name..."
        git clone "$url" "${ZSH_CUSTOM}/plugins/${name}"
    fi
done

# ---------------------------------------------------------
# 5. シンボリックリンク作成
# ---------------------------------------------------------
echo "🔗 Creating symbolic links..."

# --- User ---
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/common/gitignore_global" "$HOME/.gitignore_global"
[ -f "$DOTPATH/common/inputrc" ] && ln -sf "$DOTPATH/common/inputrc" "$HOME/.inputrc"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"

# --- Root (Environment Sync) ---
if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    # Zsh & Oh My Zsh for Root (シンボリックリンクで共有)
    $SUDO_CMD ln -sf "$HOME/.oh-my-zsh" "/root/.oh-my-zsh"
    $SUDO_CMD ln -sf "$DOTPATH/zsh/.zshrc" "/root/.zshrc"
    $SUDO_CMD ln -sf "$DOTPATH/zsh/.p10k.zsh" "/root/.p10k.zsh"
    
    # Other configs
    $SUDO_CMD ln -sf "$DOTPATH/bash/.bashrc" "/root/.bashrc"
    $SUDO_CMD ln -sf "$DOTPATH/editors/.vimrc" "/root/.vimrc"
    $SUDO_CMD ln -sf "$DOTPATH/common/gitignore_global" "/root/.gitignore_global"
    [ -f "$DOTPATH/common/inputrc" ] && $SUDO_CMD ln -sf "$DOTPATH/common/inputrc" "/root/.inputrc"
fi

# ---------------------------------------------------------
# 6. Git Setup
# ---------------------------------------------------------
echo "📝 Setting up Git..."
if [ ! -f "$HOME/.gitconfig" ]; then
    cat << EOF > "$HOME/.gitconfig"
[user]
        name = Dassult Rafale
        email = d.rafale@gmail.com
[include]
        path = $DOTPATH/common/gitconfig
EOF
else
    if ! grep -q "path = $DOTPATH/common/gitconfig" "$HOME/.gitconfig"; then
        echo -e "[include]\n\tpath = $DOTPATH/common/gitconfig" >> "$HOME/.gitconfig"
    fi
fi

# ---------------------------------------------------------
# 7. Nano Syntax Highlighting
# ---------------------------------------------------------
echo "📝 Setting up Nano..."
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi

if [ -f "$DOTPATH/editors/.nanorc" ]; then
    sed "s|DOTFILES_REAL_PATH|$DOTPATH|g" "$DOTPATH/editors/.nanorc" > "$HOME/.nanorc"
    [ -n "$SUDO_CMD" ] && $SUDO_CMD cp "$HOME/.nanorc" "/root/.nanorc"
fi

# ---------------------------------------------------------
# 8. 最終調整
# ---------------------------------------------------------
echo "🔐 Adjusting permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod 755 "$DOTPATH"
chmod 644 "$HOME/.dotfiles_env"

echo "✨ All Done! Modular Dotfiles are now active."
echo "👉 Run 'exec zsh' or 'source ~/.zshrc' to refresh your session."
