#!/usr/bin/env bats

setup() {
    MODIFIED_SCRIPT="$(mktemp)"
    sed -e 's/"$EUID"/"$MOCK_EUID"/g' \
        -e 's/\[\[ $- != \*i\* \]\]/\[\[ "${MOCK_INTERACTIVE:-$-}" != *i* \]\]/g' \
        common/_system.sh > "$MODIFIED_SCRIPT"

    shopt -s expand_aliases
    unalias() { true; }
    export -f unalias
}

teardown() {
    rm -f "$MODIFIED_SCRIPT"
}

@test "set_monokai_colors: outputs correct ansi sequences when interactive" {
    export MOCK_EUID=1000
    export MOCK_INTERACTIVE="i"

    source "$MODIFIED_SCRIPT"

    run set_monokai_colors

    [ "$status" -eq 0 ]
    [[ "$output" == *$'\e]4;0;#272822\a'* ]]
    [[ "$output" == *$'\e]11;#272822\a'* ]]
    [[ "$output" == *$'\e]10;#f8f8f2\a'* ]]
    [[ "$output" == *$'\e]12;#f92672\a'* ]]
    [[ "$output" == *$'\e]4;15;#f9f8f5\a'* ]]
}

@test "set_monokai_colors: does nothing when non-interactive" {
    export MOCK_EUID=1000
    export MOCK_INTERACTIVE="c" # non-interactive

    source "$MODIFIED_SCRIPT"

    run set_monokai_colors

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
