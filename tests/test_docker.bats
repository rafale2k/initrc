#!/usr/bin/env bats

setup() {
  MOCK_DIR="$(mktemp -d)"
  export PATH="$MOCK_DIR:$PATH"

  LOG_FILE="$(mktemp)"
  export LOG_FILE

  # Create dummy aliases so unalias in _docker.sh doesn't fail under set -e
  shopt -s expand_aliases
  alias drm=true
  alias dce=true
  source common/_docker.sh

  docker() {
    echo "docker $*" >> "$LOG_FILE"

    if [[ "$*" == *"exec -it fail-bash /bin/bash"* ]]; then
      return 1
    fi

    if [[ "$*" == "ps --format {{.Names}}" ]]; then
      echo "container1"
      echo "container2"
    fi

    return 0
  }
  export -f docker
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$LOG_FILE"
}

@test "de: executes container provided as argument" {
  run de "my-container"

  [ "$status" -eq 0 ]
  command grep "docker exec -it my-container /bin/bash" "$LOG_FILE"
}

@test "de: falls back to /bin/sh if /bin/bash fails" {
  run de "fail-bash"

  [ "$status" -eq 0 ]
  command grep "docker exec -it fail-bash /bin/bash" "$LOG_FILE"
  command grep "docker exec -it fail-bash /bin/sh" "$LOG_FILE"
}

@test "de: uses fzf to select container if no argument provided and fzf exists" {
  cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
echo "fzf $@" >> "$LOG_FILE"
echo "selected-container"
EOF
  chmod +x "$MOCK_DIR/fzf"

  # Force command -v fzf to find it
  command() {
    if [[ "$1" == "-v" && "$2" == "fzf" ]]; then
      echo "$MOCK_DIR/fzf"
      return 0
    fi
    builtin command "$@"
  }
  export -f command

  run de

  [ "$status" -eq 0 ]
  command grep "docker ps --format {{.Names}}" "$LOG_FILE"
  command grep "fzf --prompt=🐳 Select Container (Exec) >  --height 40% --reverse" "$LOG_FILE"
  command grep "docker exec -it selected-container /bin/bash" "$LOG_FILE"
}

@test "de: returns immediately if no argument and fzf does not exist" {
  command() {
    if [[ "$1" == "-v" && "$2" == "fzf" ]]; then
      return 1
    fi
    builtin command "$@"
  }
  export -f command

  run de

  [ "$status" -eq 0 ]
  run command grep "docker exec" "$LOG_FILE"
  [ "$status" -eq 1 ]
}

@test "de: returns immediately if fzf is aborted (returns empty)" {
  cat << 'EOF' > "$MOCK_DIR/fzf"
#!/bin/bash
# Returns nothing
EOF
  chmod +x "$MOCK_DIR/fzf"

  command() {
    if [[ "$1" == "-v" && "$2" == "fzf" ]]; then
      echo "$MOCK_DIR/fzf"
      return 0
    fi
    builtin command "$@"
  }
  export -f command

  run de

  [ "$status" -eq 0 ]
  run command grep "docker exec" "$LOG_FILE"
  [ "$status" -eq 1 ]
}
