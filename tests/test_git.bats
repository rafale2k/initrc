#!/usr/bin/env bats

setup() {
  MOCK_DIR="$(mktemp -d)"
  export MOCK_DIR
  export PATH="$MOCK_DIR:$PATH"

  LOG_FILE="$(mktemp)"
  export LOG_FILE

  # Create dummy aliases so unalias in _git.sh doesn't fail under set -e
  shopt -s expand_aliases
  alias gl=true
  alias g=true
  source common/_git.sh

  git() {
    echo "git $*" >> "$LOG_FILE"

    # Mock some basic git commands for g function
    if [[ "$*" == *"rev-parse --abbrev-ref HEAD"* ]]; then
      echo "main"
      return 0
    elif [[ "$*" == *"rev-parse --abbrev-ref @{u}"* ]]; then
      echo "origin/main"
      return 0
    elif [[ "$*" == *"rev-list --left-right --count"* ]]; then
      echo "2 3"
      return 0
    elif [[ "$*" == *"status --short"* ]]; then
      echo " M common/_git.sh"
      return 0
    elif [[ "$*" == *"log -3 --pretty=format"* ]]; then
      echo "abcd123 test commit 1"
      echo "defg456 test commit 2"
      echo "hijk789 test commit 3"
      return 0
    fi

    return 0
  }
  export -f git
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$LOG_FILE"
}

@test "gquick: with argument uses provided message" {
  run gquick "my test message"

  [ "$status" -eq 0 ]
  command grep "git add -A" "$LOG_FILE"
  command grep "git commit -m my test message" "$LOG_FILE"
  command grep "git push origin" "$LOG_FILE"
}

@test "g: prints branch status, changes, and recent commits" {
  run g

  [ "$status" -eq 0 ]
  # Check output contains expected sections
  echo "$output" | grep -e "-- Branch Status --"
  echo "$output" | grep -e "-- Changes --"
  echo "$output" | grep -e "-- Recent Commits --"

  # Check git commands were called
  command grep "git rev-parse --abbrev-ref HEAD" "$LOG_FILE"
  command grep "git status --short" "$LOG_FILE"
  command grep "git log -3 --pretty=format" "$LOG_FILE"
}

@test "g: passes arguments directly to git if provided" {
  run g checkout -b new-branch

  [ "$status" -eq 0 ]
  command grep "git checkout -b new-branch" "$LOG_FILE"

  # Should not call the summary functions
  run command grep "git rev-parse --abbrev-ref HEAD" "$LOG_FILE"
  [ "$status" -eq 1 ]
}

@test "gquick: without argument uses default message" {
  # Mock date command to return a fixed string
  date() {
    echo "2024-01-01 12:00:00"
  }
  export -f date

  run gquick

  [ "$status" -eq 0 ]
  command grep "git add -A" "$LOG_FILE"
  command grep "git commit -m quick update: 2024-01-01 12:00:00" "$LOG_FILE"
  command grep "git push origin" "$LOG_FILE"
}

@test "gtoday: uses git-standup if available" {
  cat << 'MOCK' > "$MOCK_DIR/git-standup"
#!/bin/bash
echo "git standup $*" >> "$LOG_FILE"
MOCK
  chmod +x "$MOCK_DIR/git-standup"

  command() {
    if [[ "$1" == "-v" && "$2" == "git-standup" ]]; then
      echo "$MOCK_DIR/git-standup"
      return 0
    fi
    builtin command "$@"
  }
  export -f command

  run gtoday --days 2

  [ "$status" -eq 0 ]
  command grep "git standup --days 2" "$LOG_FILE"
}

@test "gtoday: falls back to git log if git-standup not available" {
  command() {
    if [[ "$1" == "-v" && "$2" == "git-standup" ]]; then
      return 1
    fi
    builtin command "$@"
  }
  export -f command

  run gtoday

  [ "$status" -eq 0 ]
  command grep "git log --since=00:00:00 --all --no-merges --oneline" "$LOG_FILE"
}

@test "greview: fails when no staged changes" {
  # Mock git diff to return empty
  git() {
    if [[ "$*" == *"diff --cached"* ]]; then
      return 0 # Returns empty output
    fi
    echo "git $*" >> "$LOG_FILE"
  }
  export -f git

  run greview

  [ "$status" -eq 1 ]
  echo "$output" | command grep -e "❌ No staged changes."
}

@test "greview: calls ginv when there are staged changes" {
  # Mock git diff to return something
  git() {
    if [[ "$*" == *"diff --cached"* ]]; then
      echo "+ added new feature"
      return 0
    fi
    echo "git $*" >> "$LOG_FILE"
  }
  export -f git

  ginv() {
    echo "ginv called with: $*" >> "$LOG_FILE"
    # Also capture stdin
    cat >> "$LOG_FILE"
  }
  export -f ginv

  run greview

  [ "$status" -eq 0 ]
  command grep "ginv called with: この Git 差分を日本語で短くコードレビューして。" "$LOG_FILE"
  command grep "+ added new feature" "$LOG_FILE"
}
