#!/usr/bin/env bats

setup() {
    # Create a temporary directory for mocks
    export MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"

    # Unset variables that might interfere
    unset GEMINI_API_KEY
    unset AI_ASSIST_MODEL
}

teardown() {
    # Clean up mock directory
    rm -rf "$MOCK_DIR"
}

@test "Fails if GEMINI_API_KEY is not set and not in llm keys" {
    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    exit 1
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_DIR/fzf"

    cat << 'EOF' > "$MOCK_DIR/llm"
#!/bin/bash
if [[ "$1" == "keys" && "$2" == "list" ]]; then
    echo "openai: ***"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/llm"

    run ./bin/aic

    [ "$status" -eq 1 ]
    [[ "$output" == *"GEMINI_API_KEY is not detected"* ]]
}

@test "Fails if no changes staged" {
    export GEMINI_API_KEY="dummy_key"

    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    # Return 0 (true) to simulate NO changes
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    run ./bin/aic

    [ "$status" -eq 1 ]
    [[ "$output" == *"No changes staged. (Use 'git add' first)"* ]]
}

@test "Fails if missing required tools" {
    export GEMINI_API_KEY="dummy_key"

    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    # Return 1 to simulate changes are staged
    exit 1
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    # Not creating fzf or llm mock intentionally to simulate missing tools
    run ./bin/aic

    [ "$status" -eq 1 ]
    [[ "$output" == *"Required tools (fzf, llm) not found."* ]]
}

@test "Fails if AI fails to generate proposals" {
    export GEMINI_API_KEY="dummy_key"

    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    exit 1
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_DIR/fzf"

    cat << 'EOF' > "$MOCK_DIR/llm"
#!/bin/bash
# Simulating llm failing to generate any output
exit 0
EOF
    chmod +x "$MOCK_DIR/llm"

    run ./bin/aic

    [ "$status" -eq 1 ]
    [[ "$output" == *"AI failed to generate proposals."* ]]
}

@test "Succeeds with manual input" {
    export GEMINI_API_KEY="dummy_key"

    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    exit 1
elif [[ "$1" == "commit" && "$2" == "-m" ]]; then
    echo "MOCK_GIT_COMMIT: $3"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "[Manual Input]"
exit 0
EOF
    chmod +x "$MOCK_DIR/fzf"

    cat << 'EOF' > "$MOCK_DIR/llm"
#!/bin/bash
if [[ "$1" == "prompt" ]]; then
    echo "proposal 1"
    echo "proposal 2"
    echo "proposal 3"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/llm"

    # We need to simulate the manual input reading from standard input
    run bash -c "echo 'my manual message' | ./bin/aic"

    [ "$status" -eq 0 ]
    [[ "$output" == *"MOCK_GIT_COMMIT: my manual message"* ]]
    [[ "$output" == *"Committed successfully with Gemini 3.8 Flash!"* ]]
}

@test "Succeeds with AI proposal selection" {
    export GEMINI_API_KEY="dummy_key"

    cat << 'EOF' > "$MOCK_DIR/git"
#!/bin/bash
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--quiet" ]]; then
    exit 1
elif [[ "$1" == "commit" && "$2" == "-m" ]]; then
    echo "MOCK_GIT_COMMIT: $3"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/git"

    cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "feat(test): my ai proposal"
exit 0
EOF
    chmod +x "$MOCK_DIR/fzf"

    cat << 'EOF' > "$MOCK_DIR/llm"
#!/bin/bash
if [[ "$1" == "prompt" ]]; then
    echo "feat(test): my ai proposal"
    echo "fix(test): my ai proposal 2"
    echo "chore(test): my ai proposal 3"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/llm"

    cat << 'EOF' > "$MOCK_DIR/pbcopy"
#!/bin/bash
# Mocking pbcopy
cat > /dev/null
echo "MOCK_PBCOPY_CALLED"
exit 0
EOF
    chmod +x "$MOCK_DIR/pbcopy"

    run ./bin/aic

    [ "$status" -eq 0 ]
    [[ "$output" == *"MOCK_GIT_COMMIT: feat(test): my ai proposal"* ]]
    [[ "$output" == *"Message copied to clipboard."* ]]
    [[ "$output" == *"Committed successfully with Gemini 3.8 Flash!"* ]]
}
