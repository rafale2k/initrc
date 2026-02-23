#!/bin/bash

# 実行されたスクリプトの場所を絶対パスで取得
DOTPATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

# ---------------------------------------------------------
# 0. GitHub SSH 接続テスト & PATH設定
# ---------------------------------------------------------
echo "🔍 Checking GitHub SSH connection..."
ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new >/dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "✅ GitHub SSH connection successful."
else
    echo "⚠️  GitHub SSH connection failed. Continuing anyway..."
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
chmod 644 "$HOME/.dotfiles_env"
export PATH="$DOTPATH/bin:$PATH"

# ---------------------------------------------------------
# 3. モダンツールの自動インストール
# ---------------------------------------------------------
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget" "procps-ng" "util-linux-user")
echo "🛠️  Checking required tools..."

case "$PM" in
    "apt") 
        SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
        $SUDO_CMD apt update -y 
        ;;
    "dnf") 
        SUDO_CMD=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")
        $SUDO_CMD dnf install -y epel-release 
        $SUDO_CMD dnf config-manager --set-enabled crb || true
        ;;
    "brew")
        SUDO_CMD=""
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
                    curl -L https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz
                    [ -f "./eza" ] && mv ./eza "$DOTPATH/bin/eza"
                    chmod +x "$DOTPATH/bin/eza"
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
# 4. Zsh / Oh My Zsh & Plugins Setup (★サブモジュール連携に改良)
# ---------------------------------------------------------
echo "🐚 Setting up Zsh and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
mkdir -p "${ZSH_CUSTOM}/plugins"

# サブモジュールとして管理しているプラグインをリンク
for plugin_path in "$DOTPATH"/zsh/plugins/*; do
    name=$(basename "$plugin_path")
    if [ -d "$plugin_path" ]; then
        echo "🔗 Linking Zsh plugin: $name"
        ln -sf "$plugin_path" "${ZSH_CUSTOM}/plugins/${name}"
    fi
done

# ---------------------------------------------------------
# 5. シンボリックリンク / Git / Nano 
# ---------------------------------------------------------
echo "🔗 Creating symbolic links..."
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTPATH/editors/.vimrc" "$HOME/.vimrc"

# Nano Setup (★ここもサブモジュール前提に変更)
if [ -d "$DOTPATH/editors/nano-syntax-highlighting" ]; then
    echo "✅ Nano syntax highlighting found (submodule)."
else
    echo "⚠️  Nano syntax highlighting submodule missing. Run 'git submodule update --init'!"
fi

# ---------------------------------------------------------
# 6. ローカルテンプレート作成 
# ---------------------------------------------------------
echo "⚙️  Setting up local environment files..."
ENV_TEMPLATE="$DOTPATH/common/.env"
ENV_LOCAL="$DOTPATH/common/.env.local"

if [ -f "$ENV_TEMPLATE" ]; then
    if [ ! -f "$ENV_LOCAL" ]; then
        cp "$ENV_TEMPLATE" "$ENV_LOCAL"
        echo "✅ Created $ENV_LOCAL."
    fi
fi

# ---------------------------------------------------------
# 7. 最終確定
# ---------------------------------------------------------
echo "🔐 Finalizing permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod 755 "$DOTPATH"
chmod +x "$DOTPATH/bin/"* 2>/dev/null || true

source "$HOME/.dotfiles_env"
source "$HOME/.zshrc" 2>/dev/null || true

echo "✨ All Done! Modular Dotfiles are now active."
