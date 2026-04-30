#!/bin/bash
# ------------------------------------------------------------------------------
# common/_env_detector.sh: 環境識別 (OS種別 / 実行環境アイコン)
# loader.sh から source される。install.sh は独自に OS 判定を行う。
# ------------------------------------------------------------------------------

# --- 1. OS 種別 / パッケージマネージャー / sudo コマンドの統一判定 ---
OS_TYPE=$(uname -s)
export OS_TYPE

if [ "$OS_TYPE" = "Darwin" ]; then
    OS="mac"
    PM="brew"
    SUDO_CMD=""
    # Mac: Homebrew の標準パスを追加
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
else
    # Linux 系
    if [ -f /etc/debian_version ]; then
        OS="debian"; PM="apt"
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"; PM="dnf"
    elif grep -qi "alpine" /etc/os-release 2>/dev/null; then
        OS="alpine"; PM="apk"
    else
        OS="linux"; PM="unknown"
    fi
    SUDO_CMD="sudo"

    # Linux: コマンド名の正規化エイリアス
    if command -v batcat >/dev/null 2>&1; then alias bat='batcat'; fi
    if command -v fdfind >/dev/null 2>&1; then alias fd='fdfind'; fi
fi

export OS PM SUDO_CMD

# --- 2. 実行環境アイコン ---
get_env_icon() {
    if [ -f /.dockerenv ]; then
        echo "🐳" # Docker コンテナ
    elif grep -q "microsoft" /proc/version 2>/dev/null; then
        echo "🪟" # WSL
    elif [ -d /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        echo "🍓" # Raspberry Pi
    elif [[ "${HOSTNAME:-}" == *"cloud"* ]]; then
        echo "☁️" # クラウド系ホスト
    else
        echo "🏠" # ローカル物理マシン
    fi
}

ENV_ICON=$(get_env_icon)
export ENV_ICON
