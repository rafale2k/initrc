#!/usr/bin/env bats

setup() {
    export OLD_HOME="$HOME"
    export HOME="$(mktemp -d)"

    source common/_backup.sh
}

teardown() {
    rm -rf "$HOME"
    export HOME="$OLD_HOME"
}

@test "bu diff error path: no backup found" {
    local test_file="$HOME/test_no_backup.txt"
    echo "test content" > "$test_file"

    run bu diff "$test_file"

    [ "$status" -eq 0 ]
    [[ "$output" == *"❌ No backup found for $test_file"* ]]
}
