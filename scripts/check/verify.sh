#!/bin/bash
# shellcheck disable=SC2148,SC1090,SC1091

verify_installation() {
    local EXIT_CODE=0
    log_info "Checking Modern CLI Tools..."

    check_tool() {
        local cmd=$1
        local alt_name=${2:-""}

        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "$cmd found at $(command -v "$cmd")"
            "$cmd" --version 2>/dev/null | head -n 1 || log_warn "Version: N/A"
        elif [[ -n "$alt_name" ]] && command -v "$alt_name" >/dev/null 2>&1; then
            log_success "$alt_name found, using as $cmd (OS-specific name)"
        else
            log_error "$cmd (or $alt_name) not found in PATH.\n💡 Hint: Ensure your PATH includes /usr/local/bin or ~/bin"
            return 1
        fi
    }

    # 1. ツールチェック
    check_tool "eza" "exa" || EXIT_CODE=1
    check_tool "bat" "batcat" || EXIT_CODE=1
    check_tool "fd" "fdfind" || EXIT_CODE=1

    log_info "Checking AI Wrappers..."
    local TARGET_BIN_DIR="${HOME}/bin"
    if [[ -f "$TARGET_BIN_DIR/ginv" ]]; then
        log_success "ginv found at $TARGET_BIN_DIR/ginv"
    else
        log_warn "ginv not found at $TARGET_BIN_DIR/ginv."
    fi

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "------------------------------------------------"
        log_error "One or more critical tools are missing. Please install dependencies before proceeding."
        echo "------------------------------------------------"
        return 1
    fi
    return 0
}
