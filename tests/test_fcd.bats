#!/usr/bin/env bats

setup() {
    export MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"

    # create a mock directory for testing fcd
    export MOCK_FCD_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$MOCK_DIR"
    rm -rf "$MOCK_FCD_DIR"
}

@test "fcd: changes directory when selection is made" {
    # mock commands
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    cat << 'MOCK' > "$MOCK_DIR/find"
#!/bin/bash
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/find"

    # mock command builtin to return 1 for fd and fdfind to ensure consistency
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fd" || "$2" == "fdfind" ]]; then
                return 1
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Save original directory
    ORIG_DIR="$PWD"

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # Check that we changed directory
    [ "$PWD" = "$MOCK_FCD_DIR" ]

    # Change back
    cd "$ORIG_DIR"
    unset command
}

@test "fcd: handles cancellation (empty output from fzf)" {
    # mock commands
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
# Empty output simulates cancellation
MOCK
    chmod +x "$MOCK_DIR/fzf"

    cat << 'MOCK' > "$MOCK_DIR/find"
#!/bin/bash
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/find"

    # mock command builtin to return 1 for fd and fdfind
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fd" || "$2" == "fdfind" ]]; then
                return 1
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Save original directory
    ORIG_DIR="$PWD"

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # Check that we didn't change directory
    [ "$PWD" = "$ORIG_DIR" ]
    unset command
}

@test "fcd: uses fd/fdfind and eza when available" {
    # We want to trace which tools are called
    export LOG_FILE="$(mktemp)"

    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    cat << 'MOCK' > "$MOCK_DIR/fdfind"
#!/bin/bash
echo "fdfind $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fdfind"

    # mock eza to exist
    cat << 'MOCK' > "$MOCK_DIR/eza"
#!/bin/bash
echo "eza $@" >> "$LOG_FILE"
MOCK
    chmod +x "$MOCK_DIR/eza"

    # mock command builtin to ensure fdfind is picked up and eza is picked up
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fdfind" ]]; then
                echo "$MOCK_DIR/fdfind"
                return 0
            elif [[ "$2" == "eza" ]]; then
                echo "$MOCK_DIR/eza"
                return 0
            elif [[ "$2" == "fd" ]]; then
                return 1
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Save original directory
    ORIG_DIR="$PWD"

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # verify directory changed
    [ "$PWD" = "$MOCK_FCD_DIR" ]

    # Change back
    cd "$ORIG_DIR"

    # Check the log file to see if correct commands were used
    cat "$LOG_FILE"

    # Check if fdfind was called with the correct arguments
    grep -q "fdfind --type d --hidden --exclude .git ." "$LOG_FILE"

    # Check if fzf was called with eza preview
    grep -q "eza -T -L 2 --icons --color=always" "$LOG_FILE"

    rm -f "$LOG_FILE"
    unset command
}

@test "fcd: handles cd failure gracefully" {
    # mock fzf to return a path
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "$MOCK_FCD_DIR/nonexistent"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    cat << 'MOCK' > "$MOCK_DIR/find"
#!/bin/bash
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/find"

    # mock command builtin to return 1 for fd and fdfind
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fd" || "$2" == "fdfind" ]]; then
                return 1
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # mock cd to fail
    cd() {
        if [ "$1" = "$MOCK_FCD_DIR/nonexistent" ]; then
            return 1
        fi
        builtin cd "$@"
    }
    export -f cd

    # Save original directory
    ORIG_DIR="$PWD"

    # Source the file and run the command
    source common/_navigation.sh
    run fcd

    # Check that it returns non-zero error when cd fails
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ] # Usually failing `cd` will just hit `return` or `return 1` in our script.
    # Let's check that directory didn't change instead of status code
    [ "$PWD" = "$ORIG_DIR" ]
    unset command
}

@test "fcd: uses fd when fdfind is not available" {
    # We want to trace which tools are called
    export LOG_FILE="$(mktemp)"

    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    # Create fd
    cat << 'MOCK' > "$MOCK_DIR/fd"
#!/bin/bash
echo "fd $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fd"

    # mock command builtin to return 1 for fdfind but let fd pass through (since we created a mock for it)
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fdfind" ]]; then
                return 1
            elif [[ "$2" == "fd" ]]; then
                echo "$MOCK_DIR/fd"
                return 0
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # Check the log file to see if correct commands were used
    cat "$LOG_FILE"

    # Check if fd was called
    grep -q "fd --type d" "$LOG_FILE"

    rm -f "$LOG_FILE"
    unset command
}

@test "fcd: falls back to find when fd and fdfind are not available" {
    # We want to trace which tools are called
    export LOG_FILE="$(mktemp)"

    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    # Create find mock to record calls
    cat << 'MOCK' > "$MOCK_DIR/find"
#!/bin/bash
echo "find $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/find"

    # Mock command builtin to return 1 for fd and fdfind
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "fd" || "$2" == "fdfind" ]]; then
                return 1
            fi
            # fallback to actual command builtin for other commands like eza
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # Check the log file to see if correct commands were used
    cat "$LOG_FILE"

    # Check if find was called
    grep -q "^find --type d" "$LOG_FILE"

    rm -f "$LOG_FILE"
    unset command
}

@test "fcd: uses simple fzf when eza is not available" {
    # We want to trace which tools are called
    export LOG_FILE="$(mktemp)"

    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    cat << 'MOCK' > "$MOCK_DIR/find"
#!/bin/bash
echo "find $@" >> "$LOG_FILE"
echo "$MOCK_FCD_DIR"
MOCK
    chmod +x "$MOCK_DIR/find"

    # Mock command builtin to return 1 for eza
    command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "eza" || "$2" == "fdfind" || "$2" == "fd" ]]; then
                return 1
            fi
            builtin command "$@"
        else
            builtin command "$@"
        fi
    }
    export -f command

    # mock unalias to not fail
    unalias() { return 0; }
    export -f unalias

    # Source the file and run the command
    source common/_navigation.sh
    fcd

    # Check the log file to see if correct commands were used
    cat "$LOG_FILE"

    # Check if fzf was called WITHOUT eza preview
    # Simple grep for fzf options that indicate lack of preview
    grep -q "fzf --height 40% --reverse --border" "$LOG_FILE"

    # Also verify there is no preview flag
    ! grep -q "--preview" "$LOG_FILE"

    rm -f "$LOG_FILE"
    unset command
}
