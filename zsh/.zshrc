# 1. 環境変数の読み込み
[[ -f ~/.dotfiles_env ]] && source ~/.dotfiles_env

# 2. P10k インスタントプロンプト
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# 3. モジュール化された設定を loader 経由で読み込む
# (ここで common/loader.sh を呼ぶ。loaderが zsh/*.zsh を自動ロードする)
[[ -f "$DOTFILES_PATH/common/loader.sh" ]] && source "$DOTFILES_PATH/common/loader.sh"

# 4. zoxide (外部ツールの初期化)
eval "$(zoxide init zsh)"
