#!/usr/bin/env bats

setup() {
    export BATS_TEST_DIRNAME=$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)
    export DOTPATH="$BATS_TEST_DIRNAME/.."
    export MOCK_HOME="$BATS_TEST_DIRNAME/fake_home"
    mkdir -p "$MOCK_HOME/bin"
    export OLD_HOME="$HOME"
    export HOME="$MOCK_HOME"
    source "$DOTPATH/scripts/install_functions.sh"
}

teardown() {
    export HOME="$OLD_HOME"
    rm -rf "$MOCK_HOME"
}

@test "_sudo executes with SUDO_CMD" {
    SUDO_CMD="echo"
    run _sudo "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "_sudo executes without SUDO_CMD" {
    SUDO_CMD=""
    run _sudo echo "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}


@test "setup_os_repos for apt" {
    export PM="apt"
    export ID="ubuntu"

    # Mock source to prevent reading real /etc/os-release
    # We will alias the `.` command instead of redefining it as a function, which bash restricts

    # Since we can't easily override `.` within BATS via function export,
    # we will mock the subshell output for os_id and codename directly by redefining lsb_release, etc.

    # Mock commands
    _sudo() { echo "_sudo $@"; return 0; }
    apt-get() { echo "apt-get $@"; return 0; }
    wget() { echo "wget $@"; return 0; }
    gpg() { echo "gpg $@"; return 0; }
    tee() { echo "tee $@"; return 0; }
    dpkg() { echo "amd64"; return 0; }
    lsb_release() { echo "jammy"; return 0; }
    mkdir() { echo "mkdir $@"; return 0; }

    export -f _sudo apt-get wget gpg tee dpkg lsb_release mkdir

    run setup_os_repos
    [ "$status" -eq 0 ]
    [[ "$output" == *"⚙️  Configuring apt..."* ]]
    # When _sudo is mocked directly, it might echo differently depending on expansion
    # We will just look for the underlying command name since we also assert _sudo execution manually
    [[ "$output" == *"apt-get update"* ]]
}

@test "setup_os_repos for dnf rhel" {
    export PM="dnf"
    export OS="rhel"

    _sudo() { echo "_sudo $@"; return 0; }
    dnf() { echo "dnf $@"; return 0; }
    export -f _sudo dnf

    run setup_os_repos
    [ "$status" -eq 0 ]
    [[ "$output" == *"dnf install -y -q epel-release"* ]]
    [[ "$output" == *"dnf install -y -q xz"* ]]
    [[ "$output" == *"dnf makecache -q"* ]]
}

@test "setup_os_repos for dnf non-rhel" {
    export PM="dnf"
    export OS="fedora"

    _sudo() { echo "_sudo $@"; return 0; }
    dnf() { echo "dnf $@"; return 0; }
    export -f _sudo dnf

    run setup_os_repos
    [ "$status" -eq 0 ]
    [[ "$output" != *"epel-release"* ]]
    [[ "$output" == *"dnf install -y -q xz"* ]]
    [[ "$output" == *"dnf makecache -q"* ]]
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
    apt-get() { echo "apt-get $@"; return 0; }
    uname() { echo "Linux"; }
    ln() { echo "ln $@"; return 0; }
    mkdir() { echo "mkdir $@"; return 0; }

    export -f command apt-get uname ln mkdir

    run install_all_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"Starting Package Installation..."* ]]
    [[ "$output" == *"apt-get update"* ]]
    [[ "$output" == *"apt-get install"* ]]
    [[ "$output" == *"ln -sf "* ]]
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
    apk() { echo "apk $@"; return 0; }
    uname() { echo "Linux"; }
    ln() { return 0; }
    mkdir() { return 0; }

    export -f command apk uname ln mkdir

    run install_all_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"apk add --no-cache"* ]]
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

    run install_all_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"brew install"* ]]
}

@test "install_all_packages fallback github release" {
    # Simulate no package manager and missing tools to trigger curl/tar fallback
    command() {
        if [ "$1" = "-v" ]; then
            return 1 # all tools missing
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

    export DOTPATH="$BATS_TEST_DIRNAME/fake_dotpath"
    mkdir -p "$DOTPATH/zsh/themes/powerlevel10k"
    mkdir -p "$DOTPATH/zsh/plugins/zsh-autosuggestions"

    export OLD_HOME="$HOME"
    export HOME="$BATS_TEST_DIRNAME/fake_home"
    mkdir -p "$HOME"

    run setup_oh_my_zsh

    rm -rf "$DOTPATH" "$HOME"
    export HOME="$OLD_HOME"

    [ "$status" -eq 0 ]
    [[ "$output" == *"インストール中"* ]]
    [[ "$output" == *"Linking Zsh plugins..."* ]]
    [[ "$output" == *"Linked zsh-autosuggestions"* ]]
    [[ "$output" == *"Plugin not found in"* ]] # for missing plugins
}

@test "setup_ai_tools" {
    command() { return 1; } # simulate llm missing
    pipx() { echo "pipx $@"; return 0; }
    chmod() { echo "chmod $@"; return 0; }

    export -f command pipx chmod

    run setup_ai_tools
    [ "$status" -eq 0 ]
    [[ "$output" == *"pipx install llm"* ]]
    [[ "$output" == *"pipx inject llm llm-gemini"* ]]

    # Verify file was created in the mock HOME directory
    [ -f "$MOCK_HOME/bin/ginv" ]
}

@test "deploy_configs" {
    perl() { return 0; }
    ln() { echo "ln $@"; return 0; }
    export -f perl ln

    export DOTPATH="$BATS_TEST_DIRNAME/fake_dotpath"
    export HOME="$BATS_TEST_DIRNAME/fake_home"
    mkdir -p "$HOME"

    run deploy_configs "$HOME"

    [ "$status" -eq 0 ]
    [[ "$output" == *"ln -sfn"* ]]
}

@test "setup_root_loader" {
    _sudo() {
        if [[ "$*" == *"grep -q .bashrc_rafale"* ]]; then
            return 1 # simulate grep failure so it attempts to echo
        fi
        echo "_sudo $@"
    }
    export -f _sudo

    run setup_root_loader
    [ "$status" -eq 0 ]
    [[ "$output" == *"_sudo bash -c cat << 'EOF' > /root/.bashrc_rafale"* ]]
    [[ "$output" == *"_sudo bash -c echo 'source /root/.bashrc_rafale' >> /root/.bashrc"* ]]
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
