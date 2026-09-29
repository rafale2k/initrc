#!/usr/bin/env bats

setup() {
    export MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"
    export LOG_FILE="$(mktemp)"

    # Mock fzf to return a successful version check
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
if [[ "\$1" == "--version" ]]; then
    echo "0.38.0"
    return 0 2>/dev/null || :
fi
return 1 2>/dev/null || :
MOCK
    chmod +x "$MOCK_DIR/fzf"
}

teardown() {
    rm -rf "$MOCK_DIR"
    rm -f "$LOG_FILE"
}

@test "dl() with provided container name runs docker logs" {
    # Run the test inside bash to properly inject the mock function after sourcing
    run bash -c "
        source common/_docker.sh
        docker() { echo \"docker \$*\" >> \"$LOG_FILE\"; }
        dl \"my-container\"
    "
    [ "$status" -eq 0 ]

    command grep "docker logs -f --tail 100 my-container" "$LOG_FILE"
}

@test "dl() without container uses fzf to select and runs docker logs" {
    # Mock fzf to return a selected container name
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf-container"
MOCK
    chmod +x "$MOCK_DIR/fzf"

    run bash -c "
        source common/_docker.sh
        docker() {
            if [[ \"\$1\" == \"ps\" ]]; then
                echo \"container1\"
                echo \"fzf-container\"
                echo \"container3\"
            else
                echo \"docker \$*\" >> \"$LOG_FILE\"
            fi
        }
        dl
    "
    [ "$status" -eq 0 ]

    command grep "docker logs -f --tail 100 fzf-container" "$LOG_FILE"
}

@test "dl() without container and fzf aborts does nothing" {
    # Mock fzf to simulate user abort (empty output and non-zero exit)
    cat << 'MOCK' > "$MOCK_DIR/fzf"
#!/bin/bash
return 1 2>/dev/null || :
MOCK
    chmod +x "$MOCK_DIR/fzf"

    run bash -c "
        source common/_docker.sh
        docker() {
            if [[ \"\$1\" == \"ps\" ]]; then
                echo \"container1\"
            else
                echo \"docker \$*\" >> \"$LOG_FILE\"
            fi
        }
        dl
    "
    [ "$status" -eq 0 ]

    # Check that docker logs was NOT called
    run command grep "docker logs" "$LOG_FILE"
    [ "$status" -eq 1 ]
}

@test "dl() without container and fzf is missing does nothing" {
    # Remove fzf mock
    rm "$MOCK_DIR/fzf"

    run bash -c "
        source common/_docker.sh
        docker() {
            echo \"docker \$*\" >> \"$LOG_FILE\"
        }
        dl
    "
    [ "$status" -eq 0 ]

    # Check that docker logs was NOT called
    run command grep "docker logs" "$LOG_FILE"
    [ "$status" -eq 1 ]
}
