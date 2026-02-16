# =============================================================================
# 1. Oh My Bash セットアップ (root作業を快適に)
# =============================================================================
export OSH="/root/.oh-my-bash"

# 未インストールの場合は自動インストール
if [ ! -d "$OSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/root --unattended
fi

# テーマとプラグイン
OSH_THEME="powerline-multiline"
completions=(git composer ssh docker docker-compose)
plugins=(git bashmarks colored-man-pages)

# Oh My Bash 起動
source "$OSH/oh-my-bash.sh"

# =============================================================================
# 2. 共通設定・エイリアス読み込み
# =============================================================================
# 自作の共通エイリアスを読み込む (ここが心臓部)
DOTFILES_DIR="$HOME/dotfiles"
[[ ! -f "$DOTFILES_DIR/common/common_aliases.sh" ]] || source "$DOTFILES_DIR/common/common_aliases.sh"

# =============================================================================
# 3. インタラクティブセッション専用設定
# =============================================================================
case $- in
    *i*) ;;
    *) return;;
esac

export TERM=xterm-256color
HIST_STAMPS='yyyy-mm-dd'
OMB_USE_SUDO=true
ENABLE_CORRECTION="true"

# --- Bash固有の便利エイリアス ---
alias b='cd -'                    # 前のディレクトリに戻る
alias bashconfig='nano ~/.bashrc'
alias reload='source ~/.bashrc'
alias s='sudo -E -s'              # 環境変数を引き継いでroot化

[[ -f /home/rafale/dotfiles/common/common_aliases.sh ]] && source /home/rafale/dotfiles/common/common_aliases.sh
