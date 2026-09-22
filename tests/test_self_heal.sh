#!/bin/bash

# Setup a clean environment for testing
export DOTPATH
DOTPATH="$(pwd)"
# shellcheck source=/dev/null
source scripts/self_heal.sh

# Mock commands for testing
command() {
    if [[ "$1" == "-v" ]]; then
        local tool
        for tool in "${MOCK_MISSING_TOOLS[@]}"; do
            if [[ "$tool" == "$2" ]]; then
                return 1
            fi
        done
        return 0
    fi
    builtin command "$@"
}

whoami() {
    echo "testuser"
}

date() {
    if [[ "$1" == "+%s" ]]; then
        echo "${MOCK_DATE:-1000000}"
    else
        builtin command date "$@"
    fi
}

# Test cases
test_no_missing_tools() {
    MOCK_MISSING_TOOLS=()
    MOCK_DATE=1000000

    # clean up
    rm -f "/tmp/.dotfiles_last_check_testuser" "/tmp/.dcheck_report_testuser"

    dcheck --force

    # wait for background process
    sleep 0.2

    if [[ -f "/tmp/.dcheck_report_testuser" ]]; then
        echo "FAIL: Report file created when no tools are missing"
        return 1
    fi

    if [[ ! -f "/tmp/.dotfiles_last_check_testuser" ]]; then
        echo "FAIL: Cache file not created"
        return 1
    fi

    echo "PASS: test_no_missing_tools"
}

test_missing_tools() {
    MOCK_MISSING_TOOLS=("eza" "bat")
    MOCK_DATE=1000000

    # mock install_functions.sh in a separate temp directory to avoid modifying the real source tree
    local TEMP_DOTPATH="/tmp/mock_dotpath"
    mkdir -p "$TEMP_DOTPATH/scripts"

    cat << 'INNER_EOF' > "$TEMP_DOTPATH/scripts/install_functions.sh"
install_all_packages() {
    echo "mocked install"
}
INNER_EOF

    # temporarily change DOTPATH
    local OLD_DOTPATH="$DOTPATH"
    export DOTPATH="$TEMP_DOTPATH"

    # clean up
    rm -f "/tmp/.dotfiles_last_check_testuser" "/tmp/.dcheck_report_testuser"

    dcheck --force

    # wait for background process
    sleep 0.2

    # restore DOTPATH
    export DOTPATH="$OLD_DOTPATH"
    rm -rf "$TEMP_DOTPATH"

    if [[ ! -f "/tmp/.dcheck_report_testuser" ]]; then
        echo "FAIL: Report file not created when tools are missing"
        return 1
    fi

    local content
    content=$(cat "/tmp/.dcheck_report_testuser")
    if ! echo "$content" | grep -q "eza"; then
        echo "FAIL: 'eza' not found in report"
        return 1
    fi

    if ! echo "$content" | grep -q "bat"; then
        echo "FAIL: 'bat' not found in report"
        return 1
    fi

    echo "PASS: test_missing_tools"
}

test_cache_hit() {
    MOCK_MISSING_TOOLS=()
    MOCK_DATE=1000000

    # clean up and pre-seed cache file
    rm -f "/tmp/.dotfiles_last_check_testuser" "/tmp/.dcheck_report_testuser"
    echo "999900" > "/tmp/.dotfiles_last_check_testuser"

    # This shouldn't run because within threshold (100)
    dcheck

    # wait for background process (if it incorrectly runs)
    sleep 0.2

    # the cache shouldn't have been updated because we hit the cache
    local cache_content
    cache_content=$(cat "/tmp/.dotfiles_last_check_testuser")
    if [[ "$cache_content" != "999900" ]]; then
        echo "FAIL: Cache file updated when it shouldn't be"
        return 1
    fi

    echo "PASS: test_cache_hit"
}

test_cache_miss() {
    MOCK_MISSING_TOOLS=()
    MOCK_DATE=1000000

    # clean up and pre-seed cache file
    rm -f "/tmp/.dotfiles_last_check_testuser" "/tmp/.dcheck_report_testuser"
    echo "100000" > "/tmp/.dotfiles_last_check_testuser" # older than threshold (3600)

    dcheck

    # wait for background process
    sleep 0.2

    # the cache should have been updated
    local cache_content
    cache_content=$(cat "/tmp/.dotfiles_last_check_testuser")
    if [[ "$cache_content" != "1000000" ]]; then
        echo "FAIL: Cache file not updated"
        return 1
    fi

    echo "PASS: test_cache_miss"
}

# Run tests
fails=0
test_no_missing_tools || fails=$((fails + 1))
test_missing_tools || fails=$((fails + 1))
test_cache_hit || fails=$((fails + 1))
test_cache_miss || fails=$((fails + 1))

if [[ $fails -gt 0 ]]; then
    echo "$fails tests failed."
    exit 1
else
    echo "All tests passed!"
fi
