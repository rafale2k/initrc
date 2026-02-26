# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091,SC2034
export OSH="/root/.oh-my-bash"

# 未インストールの場合は自動インストール
if [ ! -d "$OSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/root --unattended
fi

OSH_THEME="powerline-multiline"
completions=(git composer ssh docker docker-compose)
plugins=(git bashmarks colored-man-pages)

source "$OSH/oh-my-bash.sh"
