#!/usr/bin/env bats

setup() {
  MOCK_DIR="$(mktemp -d)"
  export PATH="$MOCK_DIR:$PATH"

  LOG_FILE="$(mktemp)"
  export LOG_FILE

  shopt -s expand_aliases
  # Mock unalias to avoid errors in strict mode if 'gl' or 'g' doesn't exist
  unalias() { true; }
  export -f unalias
  alias gl=true
  alias g=true

  # Mock command builtin to avoid calling real commands
  command() { builtin command "$@"; }
  export -f command

  source ./common/_git.sh
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$LOG_FILE"
}

@test "greview fails and shows error when there are no staged changes" {
    # Mock git to return empty for diff --cached
    git() {
        if [[ "$1" == "diff" && "$2" == "--cached" ]]; then
            echo ""
            return 0
        fi
        command git "$@"
    }
    export -f git

    run greview
    [ "$status" -eq 1 ]
    [ "$output" = "❌ No staged changes." ]
}

@test "greview calls ginv when there are staged changes" {
    # Mock git to return some diff
    git() {
        if [[ "$1" == "diff" && "$2" == "--cached" ]]; then
            echo "some diff"
            return 0
        fi
        command git "$@"
    }
    export -f git

    # Mock ginv to capture its inputs
    ginv() {
        local stdin
        stdin=$(cat)
        echo "ginv called with: $stdin - この Git 差分を日本語で短くコードレビューして。"
    }
    export -f ginv

    run greview
    [ "$status" -eq 0 ]
    [ "$output" = "ginv called with: some diff - この Git 差分を日本語で短くコードレビューして。" ]
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
