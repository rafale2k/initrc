#!/usr/bin/env bats

setup() {
  MOCK_DIR="$(mktemp -d)"
  export PATH="$MOCK_DIR:$PATH"

  LOG_FILE="$(mktemp)"
  export LOG_FILE

  # Create dummy aliases so unalias in _git.sh doesn't fail under set -e
  shopt -s expand_aliases
  alias gl=true
  alias g=true

  # Mock command builtin to avoid calling real commands
  command() { builtin command "$@"; }
  export -f command
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$LOG_FILE"
}

@test "gquick: with default message and main branch fallback" {
  run bash -c "
    source common/_git.sh

    date() {
      echo '2023-10-26 12:00:00'
    }

    git() {
      echo \"git \$*\" >> \"$LOG_FILE\"
      if [[ \"\$*\" == \"symbolic-ref --short HEAD\" ]]; then
        return 1
      fi
      return 0
    }

    gquick
  "
  [ "$status" -eq 0 ]

  cat "$LOG_FILE"

  grep -q "git add -A" "$LOG_FILE"
  grep -q "git commit -m quick update: 2023-10-26 12:00:00" "$LOG_FILE"
  grep -q "git push origin main" "$LOG_FILE"
}

@test "gquick: with custom message and specific branch" {
  run bash -c "
    source common/_git.sh

    git() {
      echo \"git \$*\" >> \"$LOG_FILE\"
      if [[ \"\$*\" == \"symbolic-ref --short HEAD\" ]]; then
        echo \"feature-branch\"
        return 0
      fi
      return 0
    }

    gquick \"my custom feature message\"
  "
  [ "$status" -eq 0 ]

  cat "$LOG_FILE"

  grep -q "git add -A" "$LOG_FILE"
  grep -q "git commit -m my custom feature message" "$LOG_FILE"
  grep -q "git push origin feature-branch" "$LOG_FILE"
}
