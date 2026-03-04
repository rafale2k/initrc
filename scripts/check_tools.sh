#!/bin/bash

# --- Technical Standards ---
# This script validates the presence of modern CLI tools across different environments.
# It handles OS-specific binary naming conventions (e.g., fdfind vs fd).

set -euo pipefail

echo "--- Checking Modern CLI Tools ---"

# Function to check and link tools
check_tool() {
    local cmd=$1
    local alt_name=${2:-""}

    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd found at $(command -v "$cmd")"
        "$cmd" --version | head -n 1
    elif [[ -n "$alt_name" ]] && command -v "$alt_name" >/dev/null 2>&1; then
        echo "✅ $alt_name found, using as $cmd"
        # Optional: create a symbolic link if needed
        # ln -s "$(command -v "$alt_name")" "/usr/local/bin/$cmd"
    else
        echo "❌ $cmd (or $alt_name) not found. Searching system..."
        find / -name "$cmd" -type f 2>/dev/null | grep bin || echo "Not found anywhere"
        return 1
    fi
}

# 1. eza check (Modern replacement for ls)
check_tool "eza" "exa" || EXIT_CODE=1

# 2. bat check (cat with wings)
# On Debian/Ubuntu, it's often 'batcat'
check_tool "bat" "batcat" || EXIT_CODE=1

# 3. fd check (simple/fast alternative to find)
# On Debian/Ubuntu, it's 'fdfind'
check_tool "fd" "fdfind" || EXIT_CODE=1

echo "--- Checking AI Wrappers ---"

# Fix for the /github/home/bin issue
TARGET_BIN_DIR="${HOME}/bin"
if [[ ! -d "$TARGET_BIN_DIR" ]]; then
    echo "Directory $TARGET_BIN_DIR not found. Creating it..."
    mkdir -p "$TARGET_BIN_DIR"
fi

if [[ -f "$TARGET_BIN_DIR/ginv" ]]; then
    echo "✅ ginv found at $TARGET_BIN_DIR/ginv"
else
    echo "❌ ginv not found at $TARGET_BIN_DIR/ginv."
    echo "Content of $TARGET_BIN_DIR:"
    ls -A "$TARGET_BIN_DIR" || echo "Directory is empty"
    # Exit with error if this is a required tool
    # exit 1 
fi

if [[ ${EXIT_CODE:-0} -ne 0 ]]; then
    echo "Error: One or more critical tools are missing."
    exit 1
fi
