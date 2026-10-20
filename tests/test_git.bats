#!/usr/bin/env bats

setup() {
    MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"
    LOG_FILE="$(mktemp)"
    export LOG_FILE

    # Create dummy aliases so unalias in _git.sh doesn't fail under set -e
    shopt -s expand_aliases
    alias gl=true
    alias g=true

    # Source the file to be tested
    source common/_git.sh

    # Mock date
    date() {
        echo "2023-10-20 12:00:00"
    }
    export -f date

    # Mock git
    git() {
        echo "git $*" >> "$LOG_FILE"
        if [[ "$1" == "symbolic-ref" && "$2" == "--short" && "$3" == "HEAD" ]]; then
            if [[ "$MOCK_GIT_BRANCH_FAIL" == "1" ]]; then
                return 1
            else
                echo "feature-branch"
            fi
        fi
        return 0
    }
    export -f git
}

teardown() {
    rm -rf "$MOCK_DIR"
    rm -f "$LOG_FILE"
}

@test "gquick: with argument uses provided message and current branch" {
    run gquick "my commit message"

    [ "$status" -eq 0 ]
    command grep "git add -A" "$LOG_FILE"
    command grep "git commit -m my commit message" "$LOG_FILE"
    command grep "git symbolic-ref --short HEAD" "$LOG_FILE"
    command grep "git push origin feature-branch" "$LOG_FILE"
}

@test "gquick: without argument uses default message with date" {
    run gquick

    [ "$status" -eq 0 ]
    command grep "git add -A" "$LOG_FILE"
    command grep "git commit -m quick update: 2023-10-20 12:00:00" "$LOG_FILE"
    command grep "git push origin feature-branch" "$LOG_FILE"
}

@test "gquick: defaults to main branch if git symbolic-ref fails" {
    export MOCK_GIT_BRANCH_FAIL=1
    run gquick "fallback branch test"

    [ "$status" -eq 0 ]
    command grep "git add -A" "$LOG_FILE"
    command grep "git commit -m fallback branch test" "$LOG_FILE"
    command grep "git push origin main" "$LOG_FILE"
}
