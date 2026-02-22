#!/bin/bash
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env
[[ -f /root/.dotfiles_env ]] && source /root/.dotfiles_env

# OMB は環境依存が強いため、ここで明示的に起動
[[ -f "$DOTFILES_PATH/bash/_omb.sh" ]] && source "$DOTFILES_PATH/bash/_omb.sh"

# 共通ローダーを呼ぶだけで、bash/*.sh が自動的に読み込まれる
[[ -f "$DOTFILES_PATH/common/loader.sh" ]] && source "$DOTFILES_PATH/common/loader.sh"

eval "$(zoxide init bash)"
