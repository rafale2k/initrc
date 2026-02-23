#!/bin/bash

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# ---------------------------------------------------------
# 0. GitHub SSH 接続テスト (New!)
# ---------------------------------------------------------
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new >/dev/null 2>&1
if [ $? -eq 1 ]; then
    # ssh -T は成功時にステータス1を返す(認証は通るがシェルは提供されないため)
    echo "✅ GitHub SSH connection successful."
else
    echo "⚠️  GitHub SSH connection failed or not configured."
    echo "   Continuing anyway, but some git clones might fail if they use SSH."
fi

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
    OS="unknown"; PM="none"
fi

echo "🌍 Detected OS: $OS (using $PM)"

# ---------------------------------------------------------
# 2. パス情報の保存
# ---------------------------------------------------------
cat << EOF > "$HOME/.dotfiles_env"
export DOTFILES_PATH="$DOTPATH"
export PATH="\$DOTFILES_PATH/bin:\$PATH"
EOF

SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")

if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    TARGET_ENV="/root/.dotfiles_env"
    $SUDO_CMD sh -c "cat << EOF > $TARGET_ENV
export DOTFILES_PATH=\"$DOTPATH\"
export PATH=\"$DOTPATH/bin:\\\$PATH\"
EOF"
fi

# ---------------------------------------------------------
# 3. モダンツールの自動インストール
# ---------------------------------------------------------
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget" "procps-ng" "util-linux-user")
echo "🛠️  Checking required tools..."

case "$PM" in
    "apt") $SUDO_CMD apt update -y ;;
    "dnf") 
        $SUDO_CMD dnf install -y epel-release 
        $SUDO_CMD dnf config-manager --set-enabled crb || true
        ;;
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
            "dnf")
                if [ "$tool" = "eza" ]; then
                    echo "📥 eza not found in dnf. Downloading binary..."
                    curl -L https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz
                    mv eza "$DOTPATH/bin/" && chmod +x "$DOTPATH/bin/eza"
                else
                    $SUDO_CMD dnf install -y "$tool" || echo "⚠️  Failed to install $tool via dnf"
                fi
                ;;
        esac
    else
        echo "✅ $tool is already installed."
    fi
done

# ---------------------------------------------------------
# 4. Zsh / Oh My Zsh & Plugins Setup
# ---------------------------------------------------------
echo "🐚 Setting up Zsh and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
PLUGINS_URLS=(
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
)

for item in "${PLUGINS_URLS[@]}"; do
    name=${item%%:*}; url=${item#*:}
    [ ! -d "${ZSH_CUSTOM}/plugins/${name}" ] && git clone "$url" "${ZSH_CUSTOM}/plugins/${name}"
done

# ---------------------------------------------------------
# 5. シンボリックリンク / Git / Nano 
# ---------------------------------------------------------
echo "🔗 Creating symbolic links..."
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"

if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    $SUDO_CMD ln -sf "$HOME/.oh-my-zsh" "/root/.oh-my-zsh"
    $SUDO_CMD ln -sf "$DOTPATH/zsh/.zshrc" "/root/.zshrc"
fi

# Nano Setup
if [ ! -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    git clone https://github.com/galenguyer/nano-syntax-highlighting.git "$DOTPATH/editors/nano-syntax-highlighting"
fi

# ---------------------------------------------------------
# 6. 最終調整
# ---------------------------------------------------------
echo "🔐 Adjusting permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod 755 "$DOTPATH"
[ -f "$DOTPATH/bin/gcm" ] && chmod +x "$DOTPATH/bin/gcm"
chmod 644 "$HOME/.dotfiles_env"

echo "✨ All Done! Modular Dotfiles are now active."
echo "👉 Run 'exec zsh' to refresh your session."
