#!/usr/bin/env bats

setup() {
    MOCK_HOME="$(mktemp -d)"
    export MOCK_HOME
    export HOME="$MOCK_HOME"

    # Source the backup script
    source common/_backup.sh
}

teardown() {
    rm -rf "$MOCK_HOME"
}

@test "bu: no arguments shows usage" {
    run bu
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: bu [add] <file_path>"* ]]
}

@test "bu: creates backup with explicit add" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    run bu add "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup created:"* ]]

    # Verify backup exists
    local backup_count
    backup_count=$(find "$HOME/.dotfiles_backup/manual" -name "test.txt_*.bak" | wc -l)
    [ "$backup_count" -eq 1 ]
}

@test "bu: creates backup implicitly when passing just a file path" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    run bu "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup created:"* ]]

    # Verify backup exists
    local backup_count
    backup_count=$(find "$HOME/.dotfiles_backup/manual" -name "test.txt_*.bak" | wc -l)
    [ "$backup_count" -eq 1 ]
}

@test "bu diff: shows diff for modified file" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    # Create backup
    bu "$test_file"

    # Modify file
    echo "world" > "$test_file"

    # diff exits with 1 when differences are found
    run bu diff "$test_file"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Comparing"* ]]
    [[ "$output" == *"-hello"* ]]
    [[ "$output" == *"+world"* ]]
}

@test "bu diff: error when no backup exists" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    run bu diff "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No backup found for"* ]]
}

@test "bu restore: cancels restore when answering no" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    # Create backup
    bu "$test_file"

    # Modify file
    echo "world" > "$test_file"

    # Run restore and answer no
    # shellcheck disable=SC2317
    do_restore() {
        echo 'n' | bu restore "$1"
    }

    run do_restore "$test_file"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Cancelled."* ]]

    # Verify file wasn't restored
    run cat "$test_file"
    [[ "$output" == "world" ]]
}

@test "bu restore: restores file when answering yes" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    # Create backup
    bu "$test_file"

    # Modify file
    echo "world" > "$test_file"

    # Run restore and answer yes
    # shellcheck disable=SC2317
    do_restore() {
        echo 'y' | bu restore "$1"
    }

    run do_restore "$test_file"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Restored $test_file"* ]]

    # Verify file was restored
    run cat "$test_file"
    [[ "$output" == "hello" ]]
}

@test "eb: calls bu and n" {
    local test_file="$HOME/test.txt"
    echo "hello" > "$test_file"

    # mock n
    n() {
        echo "mock n called for $1"
    }
    export -f n

    run eb "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup created:"* ]]
    [[ "$output" == *"mock n called for $test_file"* ]]
}
