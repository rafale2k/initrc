#!/usr/bin/env bats
@test "source file" {
  shopt -s expand_aliases
  alias drm=echo
  alias dce=echo
  source common/_docker.sh
  type dri
}
