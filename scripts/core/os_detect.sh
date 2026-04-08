#!/bin/bash
# shellcheck disable=SC2148

detect_os_and_pm() {
    export OS="unknown"
    export PM="unknown"
    export SUDO_CMD="sudo"

    if [ "$(uname)" = "Darwin" ]; then
        export OS="mac"
        export PM="brew"
        export SUDO_CMD=""
    elif [ -f /etc/debian_version ]; then
        export OS="debian"
        export PM="apt"
    elif [ -f /etc/redhat-release ]; then
        export OS="rhel"
        export PM="dnf"
    elif command -v apk >/dev/null 2>&1; then
        export OS="alpine"
        export PM="apk"
    fi

    log_info "Detected OS: $OS (using $PM)"
}
