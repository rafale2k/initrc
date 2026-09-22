#!/usr/bin/env bats

setup() {
  # We will use sed to replace /etc/os-release with our MOCK_OS_RELEASE in a temporary copy of the script.
  # This avoids trying to mock the '.' builtin.

  MOCK_DIR="$(mktemp -d)"
  export PATH="$MOCK_DIR:$PATH"

  LOG_FILE="$(mktemp)"
  export LOG_FILE

  MOCK_OS_RELEASE="$(mktemp)"
  export MOCK_OS_RELEASE

  # Create a modified version of the script pointing to our mock os-release
  MODIFIED_SCRIPT="$(mktemp)"
  export MODIFIED_SCRIPT
  sed "s|/etc/os-release|$MOCK_OS_RELEASE|g" ./scripts/install_functions.sh > "$MODIFIED_SCRIPT"
  source "$MODIFIED_SCRIPT"

  _sudo() {
    echo "_sudo $*" >> "$LOG_FILE"
    return 0
  }
  export -f _sudo

  cat << 'MOCK' > "$MOCK_DIR/dpkg"
#!/bin/bash
if [ "$1" = "--print-architecture" ]; then
    echo "amd64"
fi
MOCK
  chmod +x "$MOCK_DIR/dpkg"

  cat << 'MOCK' > "$MOCK_DIR/wget"
#!/bin/bash
echo "wget $*" >> "$LOG_FILE"
MOCK
  chmod +x "$MOCK_DIR/wget"

  cat << 'MOCK' > "$MOCK_DIR/lsb_release"
#!/bin/bash
if [ "$1" = "-cs" ]; then
    echo "mock-codename"
fi
MOCK
  chmod +x "$MOCK_DIR/lsb_release"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$LOG_FILE"
  rm -f "$MOCK_OS_RELEASE"
  rm -f "$MODIFIED_SCRIPT"
}

@test "setup_os_repos configures apt correctly for ubuntu" {
  export PM="apt"

  cat << 'MOCK_OS' > "$MOCK_OS_RELEASE"
ID=ubuntu
VERSION_CODENAME=jammy
MOCK_OS

  run setup_os_repos
  [ "$status" -eq 0 ]

  command grep "_sudo apt-get update -qq" "$LOG_FILE"
  command grep "_sudo apt-get install -y -qq wget gnupg curl ca-certificates lsb-release xz-utils" "$LOG_FILE"
  command grep "_sudo mkdir -p /etc/apt/keyrings" "$LOG_FILE"
  command grep "wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" "$LOG_FILE"
  command grep "_sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg" "$LOG_FILE"
  command grep "_sudo tee /etc/apt/sources.list.d/gierens.list" "$LOG_FILE"
  command grep "wget -qO- https://download.docker.com/linux/ubuntu/gpg" "$LOG_FILE"
  command grep "_sudo tee /etc/apt/sources.list.d/docker.list" "$LOG_FILE"
}

@test "setup_os_repos configures apt correctly for debian using fallback grep" {
  export PM="apt"

  cat << 'MOCK_OS' > "$MOCK_OS_RELEASE"
ID=debian
VERSION_CODENAME=bookworm
MOCK_OS

  cat << 'MOCK' > "$MOCK_DIR/lsb_release"
#!/bin/bash
return 1 2>/dev/null || :
MOCK

  run setup_os_repos
  [ "$status" -eq 0 ]

  command grep "wget -qO- https://download.docker.com/linux/debian/gpg" "$LOG_FILE"
}

@test "setup_os_repos configures apt but apt-get update fails" {
  export PM="apt"

  cat << 'MOCK_OS' > "$MOCK_OS_RELEASE"
ID=ubuntu
VERSION_CODENAME=jammy
MOCK_OS

  _sudo() {
    echo "_sudo $@" >> "$LOG_FILE"
    if [ "$1" = "apt-get" ] && [ "$2" = "update" ]; then
        return 1
    fi
    return 0
  }
  export -f _sudo

  run setup_os_repos
  [ "$status" -eq 0 ]

  command grep "_sudo apt-get update -qq" "$LOG_FILE"
  run command grep "_sudo apt-get install -y -qq wget" "$LOG_FILE"
  [ "$status" -eq 1 ]
}

@test "setup_os_repos configures dnf correctly for non-rhel" {
  export PM="dnf"
  export OS="fedora"

  run setup_os_repos
  [ "$status" -eq 0 ]

  command grep "_sudo dnf install -y -q xz" "$LOG_FILE"
  command grep "_sudo dnf makecache -q" "$LOG_FILE"
  run command grep "_sudo dnf install -y -q epel-release" "$LOG_FILE"
  [ "$status" -eq 1 ]
}

@test "setup_os_repos configures dnf correctly for rhel" {
  export PM="dnf"
  export OS="rhel"

  run setup_os_repos
  [ "$status" -eq 0 ]

  command grep "_sudo dnf install -y -q epel-release" "$LOG_FILE"
  command grep "_sudo dnf install -y -q xz" "$LOG_FILE"
  command grep "_sudo dnf makecache -q" "$LOG_FILE"
}

@test "setup_os_repos does nothing for unknown PM" {
  export PM="pacman"

  run setup_os_repos
  [ "$status" -eq 0 ]
  [ ! -s "$LOG_FILE" ]
}
