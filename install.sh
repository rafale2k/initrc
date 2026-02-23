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
# 全OS共通のパッケージリスト
REQUIRED_TOOLS=("tree" "git" "curl" "vim" "nano" "fzf" "ccze" "zsh" "zoxide" "bat" "eza" "fd" "jq" "wget")
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
        # RHEL系特有のパッケージをここで個別に叩く
        echo "📦 Installing RHEL-specific packages..."
        $SUDO_CMD dnf install -y procps-ng util-linux-user || true
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
# 4. Zsh / Oh My Zsh & Plugins Setup
# ---------------------------------------------------------
echo "🐚 Setting up Zsh and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
mkdir -p "${ZSH_CUSTOM}/plugins"

if [ -d "$DOTPATH/zsh/plugins" ]; then
    for plugin_path in "$DOTPATH"/zsh/plugins/*; do
        name=$(basename "$plugin_path")
        if [ -d "$plugin_path" ]; then
            echo "🔗 Linking Zsh plugin: $name"
            ln -sf "$plugin_path" "${ZSH_CUSTOM}/plugins/${name}"
        fi
    done
fi

# ---------------------------------------------------------
# 5. シンボリックリンク & nanorc 動的生成
# ---------------------------------------------------------
echo "🔗 Creating symbolic links from configs/..."
if [ -d "$DOTPATH/configs" ]; then
    for config_file in "$DOTPATH"/configs/*; do
        filename=$(basename "$config_file")
        target="$HOME/.$filename"

        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "📦 Backing up $target to ${target}.bak"
            mv "$target" "${target}.bak"
        fi

        if [ "$filename" == "nanorc" ]; then
            echo "📝 Generating $target (Path substitution for Monokai)..."
            sed "s|__DOTPATH__|$DOTPATH|g" "$config_file" > "$target"
        else
            echo "✅ Linking $filename -> $target"
            ln -sf "$config_file" "$target"
        fi
    done
fi

# 個別リンク（テーマファイルなど）
echo "🔗 Creating additional shell & theme links..."
ln -sf "$DOTPATH/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTPATH/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
mkdir -p "$HOME/.nano"
ln -sf "$DOTPATH/editors/my-themes/monokai.nanorc" "$HOME/.nano/monokai.nanorc"

# ---------------------------------------------------------
# 6. ローカルテンプレート作成 
# ---------------------------------------------------------
ENV_TEMPLATE="$DOTPATH/common/.env"
ENV_LOCAL="$DOTPATH/common/.env.local"
[ -f "$ENV_TEMPLATE" ] && [ ! -f "$ENV_LOCAL" ] && cp "$ENV_TEMPLATE" "$ENV_LOCAL"

# ---------------------------------------------------------
# 7. 最終確定
# ---------------------------------------------------------
echo "🔐 Finalizing permissions..."
[ -n "$SUDO_CMD" ] && $SUDO_CMD chown -R $(whoami):$(whoami) "$DOTPATH"
chmod +x "$DOTPATH/bin/"* 2>/dev/null || true

source "$HOME/.dotfiles_env"
[ -n "$ZSH_VERSION" ] && source "$HOME/.zshrc" 2>/dev/null || true

# ---------------------------------------------------------
# 8. ターミナルパレットの強制適用 (rlogin対策)
# ---------------------------------------------------------
if [ -f "$DOTPATH/bin/monokai-palette.sh" ]; then
    echo "🎨 Applying Monokai palette to terminal..."
    chmod +x "$DOTPATH/bin/monokai-palette.sh"
    bash "$DOTPATH/bin/monokai-palette.sh"
fi

echo "✨ All Done! System Recreated."
