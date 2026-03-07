# shellcheck shell=bash
# --- bash/functions.sh ---

copyfile() {
    if [ -z "$1" ] || [ ! -f "$1" ]; then
        echo "Usage: copyfile <file>"
        return 1
    fi

    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -z "$DISPLAY" ]; then
        # SC2059 対策
        printf "\033]52;c;%s\007" "$(base64 < "$1" | tr -d '\n')"
        echo "✅ Copied $1 to local clipboard (via OSC 52 over SSH)"
        return 0
    fi

    if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard < "$1"
        echo "✅ Copied $1 to clipboard (via xclip)"
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input < "$1"
        echo "✅ Copied $1 to clipboard (via xsel)"
    else
        echo "Error: No clipboard tool found."
        return 1
    fi
}
