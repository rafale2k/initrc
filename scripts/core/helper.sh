#!/bin/bash
# shellcheck disable=SC2148

_sudo() {
    if [ -z "${SUDO_CMD:-}" ]; then "$@"; else $SUDO_CMD "$@"; fi
}
