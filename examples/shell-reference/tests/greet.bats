#!/usr/bin/env bats
# Real tests for the reference project's own scripts. They load the bats helper
# deposited by bootstrap (tests/test_helper.bash) and use REPO_ROOT (set by that
# helper) to locate bin/. This proves the deposited harness is actually usable.
load test_helper

@test "greet defaults to 'Hello, world!'" {
  run "$REPO_ROOT/bin/greet"
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, world!" ]
}

@test "greet uses the provided name" {
  run "$REPO_ROOT/bin/greet" Ada
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Ada!" ]
}
