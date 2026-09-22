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

@test "_sudo executes with SUDO_CMD" {
    # Undo the _sudo mock from setup() to test the original function
    source scripts/install_functions.sh
    SUDO_CMD="echo"
    run _sudo "hello"
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello"* ]]
}

@test "_sudo executes without SUDO_CMD" {
    # Undo the _sudo mock from setup() to test the original function
    source scripts/install_functions.sh
    SUDO_CMD=""
    run _sudo echo "hello"
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello"* ]]
}

@test "install_all_packages with apt-get" {
    command() {
        if [ "$1" = "-v" ]; then
            case "$2" in
                apt-get) return 0 ;;
                bat|fd|eza|batcat|fdfind) return 0 ;;
                *) return 1 ;;
            esac
        fi
    }
    apt-get() { echo "apt-get $@" >> "$LOG_FILE"; return 0; }
    uname() { echo "Linux"; }
    ln() { echo "ln $@" >> "$LOG_FILE"; return 0; }
    mkdir() { echo "mkdir $@" >> "$LOG_FILE"; return 0; }

    export -f command apt-get uname ln mkdir

    export HOME="$MOCK_DIR/fake_home"

    run install_all_packages
    [ "$status" -eq 0 ]
    command grep "apt-get update" "$LOG_FILE"
    command grep "apt-get install" "$LOG_FILE"
    command grep "ln -sf" "$LOG_FILE"
}

@test "install_all_packages with apk" {
    command() {
        if [ "$1" = "-v" ]; then
            case "$2" in
                apk) return 0 ;;
                bat|fd|eza) return 0 ;;
                *) return 1 ;;
            esac
        fi
    }
    apk() { echo "apk $@" >> "$LOG_FILE"; return 0; }
    uname() { echo "Linux"; }
    ln() { return 0; }
    mkdir() { return 0; }

    export -f command apk uname ln mkdir

    export HOME="$MOCK_DIR/fake_home"

    run install_all_packages
    [ "$status" -eq 0 ]
    command grep "apk add --no-cache" "$LOG_FILE"
}

@test "install_all_packages with brew (macOS)" {
    command() {
        if [ "$1" = "-v" ]; then
            case "$2" in
                brew) return 0 ;;
                bat|fd|eza) return 0 ;;
                *) return 1 ;;
            esac
        fi
    }
    brew() { echo "brew $@"; return 0; }
    uname() { echo "Darwin"; }
    ln() { return 0; }
    mkdir() { return 0; }

    export -f command brew uname ln mkdir

    export HOME="$MOCK_DIR/fake_home"

    run install_all_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"brew install"* ]]
}

@test "install_all_packages fallback github release" {
    command() {
        if [ "$1" = "-v" ]; then
            return 1
        fi
    }
    uname() {
        if [ "$1" = "-m" ]; then echo "x86_64"; else echo "Linux"; fi
    }
    curl() { echo "curl $@"; return 0; }
    tar() { echo "tar $@"; return 0; }
    find() { echo "find $@"; return 0; }
    chmod() { echo "chmod $@"; return 0; }
    mkdir() { return 0; }
    awk() { echo "v1.0.0"; }

    export -f command uname curl tar find chmod mkdir awk

    export HOME="$MOCK_DIR/fake_home"

    run install_all_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"tar xz -C "* ]]
    [[ "$output" == *"Downloading latest bat binary"* ]]
    [[ "$output" == *"Downloading latest fd binary"* ]]
}

@test "setup_oh_my_zsh" {
    sh() { echo "sh $@"; return 0; }
    curl() { echo "curl $@"; return 0; }

    export -f sh curl

    export DOTPATH="$MOCK_DIR/fake_dotpath"
    mkdir -p "$DOTPATH/zsh/themes/powerlevel10k"
    mkdir -p "$DOTPATH/zsh/plugins/zsh-autosuggestions"

    export HOME="$MOCK_DIR/fake_home"
    mkdir -p "$HOME"

    run setup_oh_my_zsh

    [ "$status" -eq 0 ]
    [[ "$output" == *"インストール中"* ]]
    [[ "$output" == *"Linking Zsh plugins..."* ]]
    [[ "$output" == *"Linked zsh-autosuggestions"* ]]
    [[ "$output" == *"Plugin not found in"* ]]
}

@test "setup_ai_tools" {
    command() { return 1; }
    pipx() { echo "pipx $@"; return 0; }
    chmod() { echo "chmod $@"; return 0; }

    export -f command pipx chmod
    export HOME="$MOCK_DIR/fake_home"
    mkdir -p "$HOME/bin"

    run setup_ai_tools
    [ "$status" -eq 0 ]
    [[ "$output" == *"pipx install llm"* ]]
    [[ "$output" == *"pipx inject llm llm-gemini"* ]]

    [ -f "$HOME/bin/ginv" ]
}

@test "deploy_configs" {
    perl() { return 0; }
    ln() { echo "ln $@"; return 0; }
    export -f perl ln

    export DOTPATH="$MOCK_DIR/fake_dotpath"
    export HOME="$MOCK_DIR/fake_home"
    mkdir -p "$HOME"

    run deploy_configs "$HOME"

    [ "$status" -eq 0 ]
    [[ "$output" == *"ln -sfn"* ]]
}

@test "setup_root_loader" {
    # _sudo is overridden in setup() to write to LOG_FILE, we temporarily undo that
    # or just assert on LOG_FILE.

    _sudo() {
        if [[ "$*" == *"grep -q .bashrc_rafale"* ]]; then
            return 1
        fi
        echo "_sudo $@" >> "$LOG_FILE"
    }
    export -f _sudo

    run setup_root_loader
    [ "$status" -eq 0 ]
    command grep "_sudo bash -c cat << 'EOF' > /root/.bashrc_rafale" "$LOG_FILE"
    command grep "_sudo bash -c echo 'source /root/.bashrc_rafale' >> /root/.bashrc" "$LOG_FILE"
}

@test "verify_installation with all tools missing" {
    command() { return 1; }
    export -f command

    run verify_installation
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: One or more critical tools are missing."* ]]
}

@test "verify_installation success" {
    eza() { echo "eza 1.0.0"; }
    bat() { echo "bat 1.0.0"; }
    fd() { echo "fd 1.0.0"; }
    export -f eza bat fd

    command() {
        if [ "$1" = "-v" ]; then
            case "$2" in
                eza|bat|fd) return 0 ;;
                *) return 1 ;;
            esac
        fi
    }
    export -f command

    run verify_installation
    [ "$status" -eq 0 ]
}
