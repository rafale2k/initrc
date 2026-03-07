# shellcheck shell=bash
# --- bash/functions.sh ---

copyfile() {
    if [ -z "$1" ] || [ ! -f "$1" ]; then
        echo "Usage: copyfile <file>"
        return 1
    fi

    # SSH接続中、またはDISPLAY変数が空ならOSC 52を優先
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -z "$DISPLAY" ]; then
        printf "\033]52;c;$(base64 < "$1" | tr -d '\n')\007"
        echo "✅ Copied $1 to local clipboard (via OSC 52 over SSH)"
        return 0
    fi

    # ローカルでのフォールバック
    if command -v xclip >/dev/null 2>&1; then
        cat "$1" | xclip -selection clipboard
        echo "✅ Copied $1 to clipboard (via xclip)"
    elif command -v xsel >/dev/null 2>&1; then
        cat "$1" | xsel --clipboard --input
        echo "✅ Copied $1 to clipboard (via xsel)"
    else
        echo "Error: No clipboard tool found."
        return 1
    fi
}
