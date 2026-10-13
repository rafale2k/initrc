#!/usr/bin/env bats

setup() {
    MODIFIED_SCRIPT="$(mktemp)"
    sed 's/"$EUID"/"$MOCK_EUID"/g' bash/rafale-sre.theme.sh > "$MODIFIED_SCRIPT"

    _omb_util_add_prompt_command() {
        return 0
    }
    export -f _omb_util_add_prompt_command
}

teardown() {
    rm -f "$MODIFIED_SCRIPT"
}

@test "PROMPT_COMMAND basic functionality for non-root user" {
    source "$MODIFIED_SCRIPT"
    export MOCK_EUID=1000
    export ENV_ICON=""

    true
    _omb_theme_PROMPT_COMMAND

    [[ "$PS1" == *"\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;36m\]\w\[\e[0m\]\n❯ "* ]]
    [[ "$PS1" != *"\[\e[1;31m\][!] "* ]]
    [[ "$PS1" != *"ROOT"* ]]
}

@test "PROMPT_COMMAND non-zero exit code adds error marker" {
    source "$MODIFIED_SCRIPT"
    export MOCK_EUID=1000
    export ENV_ICON=""

    # We can invoke it by forcing the exit code
    (exit 1) || _omb_theme_PROMPT_COMMAND

    [[ "$PS1" == *"\[\e[1;31m\][!] "* ]]
}

@test "PROMPT_COMMAND root user adds ROOT marker and changes symbol" {
    source "$MODIFIED_SCRIPT"
    export MOCK_EUID=0
    export ENV_ICON=""

    true
    _omb_theme_PROMPT_COMMAND

    [[ "$PS1" == *"ROOT"* ]]
    [[ "$PS1" == *"# "* ]]
    [[ "$PS1" != *"❯ "* ]]
}

@test "PROMPT_COMMAND prepends ENV_ICON when set" {
    source "$MODIFIED_SCRIPT"
    export MOCK_EUID=1000
    export ENV_ICON="🐳"

    true
    _omb_theme_PROMPT_COMMAND

    [[ "$PS1" == "🐳 "* ]]
}
