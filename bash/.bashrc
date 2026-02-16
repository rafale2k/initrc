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

# =============================================================================
# 4. Rlogin / ターミナル配色設定 (Tokyo Night)
# =============================================================================
if [[ "$TERM" == "xterm-256color" ]]; then
    # 背景・文字・カーソル
    printf "\033]11;#1a1b26\007"
    printf "\033]10;#a9b1d6\007"
    printf "\033]12;#7aa2f7\007"
    # ANSIカラーパレット (0-15)
    printf "\033]4;0;#414868;1;#f7768e;2;#9ece6a;3;#e0af68;4;#7aa2f7;5;#bb9af7;6;#7dcfff;7;#a9b1d6\007"
    printf "\033]4;8;#414868;9;#f7768e;10;#9ece6a;11;#e0af68;12;#7aa2f7;13;#bb9af7;14;#7dcfff;15;#c0caf5\007"
fi
