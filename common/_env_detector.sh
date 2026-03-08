# 環境識別アイコンを返す関数
get_env_icon() {
    if [ -f /.dockerenv ]; then
        echo "🐳" # Dockerコンテナ
    elif grep -q "microsoft" /proc/version 2>/dev/null; then
        echo "🪟" # WSL
    elif [ -d /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model; then
        echo "🍓" # Raspberry Pi
    elif [[ "$HOSTNAME" == *"cloud"* ]]; then
        echo "☁️" # なんとなくクラウド
    else
        echo "🏠" # ローカル物理マシン
    fi
}
export ENV_ICON=$(get_env_icon)
