# shellcheck shell=bash
# shellcheck disable=SC2034,SC2148,SC1090,SC1091
# 履歴設定
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
HIST_STAMPS="yyyy-mm-dd"

# 補完設定
zstyle ':completion:*' menu select

# その他
export ARCHFLAGS="-arch $(uname -m)"
