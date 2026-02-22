# 履歴設定
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
HIST_STAMPS="yyyy-mm-dd"

# 補完設定
zstyle ':completion:*' menu select

# その他
export ARCHFLAGS="-arch $(uname -m)"
