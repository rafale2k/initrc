#!/bin/bash
# shellcheck disable=SC2148,SC1090,SC1091

setup_ai_tools() {
    if ! command -v llm >/dev/null 2>&1; then
        pipx install llm && pipx inject llm llm-gemini
    fi
    cat << 'EOF' > "$HOME/bin/ginv"
#!/bin/bash
[ -z "$1" ] && exit 1
llm "$1" -m gemini-2.5-flash --no-stream
EOF
    chmod +x "$HOME/bin/ginv"
    log_success "AI tools configured"
}
