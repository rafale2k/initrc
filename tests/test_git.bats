#!/usr/bin/env bats

setup() {
    shopt -s expand_aliases

    # Mock unalias to avoid errors in strict mode if 'gl' or 'g' doesn't exist
    unalias() { true; }
    export -f unalias
    alias gl=true
    alias g=true

    source ./common/_git.sh
}

@test "greview fails and shows error when there are no staged changes" {
    # Mock git to return empty for diff --cached
    git() {
        if [[ "$1" == "diff" && "$2" == "--cached" ]]; then
            echo ""
            return 0
        fi
        command git "$@"
    }
    export -f git

    run greview
    [ "$status" -eq 1 ]
    [ "$output" = "❌ No staged changes." ]
}

@test "greview calls ginv when there are staged changes" {
    # Mock git to return some diff
    git() {
        if [[ "$1" == "diff" && "$2" == "--cached" ]]; then
            echo "some diff"
            return 0
        fi
        command git "$@"
    }
    export -f git

    # Mock ginv to capture its inputs
    ginv() {
        local stdin
        stdin=$(cat)
        echo "ginv called with: $stdin - $1"
    }
    export -f ginv

    run greview
    [ "$status" -eq 0 ]
    [ "$output" = "ginv called with: some diff - この Git 差分を日本語で短くコードレビューして。" ]
}
