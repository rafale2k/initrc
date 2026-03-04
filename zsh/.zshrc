# ------------------------------------------------------------------------------
# .zshrc: プロンプト消失回避・統合完成版
# ------------------------------------------------------------------------------

# 1. Powerlevel10k インスタントプロンプト (最優先)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# 2. パス・環境変数定義
typeset -U path
export DOTPATH="${DOTPATH:-$HOME/dotfiles}"
export DOTFILES="$DOTPATH"
export ZSH="$HOME/.oh-my-zsh"
export EDITOR=nano

# PATH設定 (右側優先: 重複を排除しつつ bin を先頭に)
path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  $path
)
export PATH

# 3. テーマ選択 (Oh My Zsh のカスタムディレクトリ対応)
ZSH_THEME="powerlevel10k/powerlevel10k"

# 4. プラグイン設定 (右側の構成 + 便利な history 検索を追加)
plugins=(
    git
    git-extras
    docker
    docker-compose
    copyfile
    copypath
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-search-multi-word
)

# 5. Oh My Zsh の読み込み
source $ZSH/oh-my-zsh.sh

# 6. Powerlevel10k の設定読み込み (テーマが読み込まれた後に実行)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ------------------------------------------------------------------------------
# 7. 補完・シェルオプション (左側の「いいとこ取り」を復活)
# ------------------------------------------------------------------------------
# 動作を快適にする設定（左側から継承）
setopt print_eight_bit      # 日本語表示
setopt no_beep              # ビープ音消去
setopt interactive_comments # プロンプトで # 以降をコメント視
setopt auto_cd              # ディレクトリ名だけで移動
setopt auto_pushd           # cd で履歴をスタック
setopt share_history        # 履歴共有
setopt hist_ignore_all_dups # 重複履歴無視
setopt correct              # コマンド修正案表示

# 補完の挙動を賢くする（左側から継承）
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 大文字小文字を区別しない
zstyle ':completion:*' ignore-parents parent pwd .. # 親ディレクトリ等は補完しない
zstyle ':completion:*:default' menu select=1        # メニュー選択モード

# ------------------------------------------------------------------------------
# 8. 共通ローダー (自作エイリアスなど)
# ------------------------------------------------------------------------------
# install.sh で置換されるプレースホルダー
DOTFILES_ROOT="__DOTPATH__"
[ "$DOTFILES_ROOT" = "__DOTPATH__" ] && DOTFILES_ROOT="$DOTPATH"

# 1. 司令塔 loader.sh を呼び出す
if [ -f "$DOTFILES_ROOT/common/loader.sh" ]; then
    source "$DOTFILES_ROOT/common/loader.sh"
fi

# zoxide / fzf (ツールがインストールされていれば有効化)
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
