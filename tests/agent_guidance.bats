#!/usr/bin/env bats
load test_helper

assert_shared_guidance() {
  run "$BS" apply --profile "$1" --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [ -f "$PROJ/AGENTS.md" ]
  grep -q '^## Commands' "$PROJ/AGENTS.md"
  grep -q '^@AGENTS.md$' "$PROJ/CLAUDE.md"
  # Commands and project context must have one owner, shared by both clients.
  ! grep -q '^## Commands' "$PROJ/CLAUDE.md"
  ! grep -q '^## Stack' "$PROJ/CLAUDE.md"
}

@test "minimal deposits shared project guidance and a Claude import" {
  assert_shared_guidance minimal
}

@test "Symfony deposits shared project guidance and a Claude import" {
  assert_shared_guidance symfony
}

@test "WordPress deposits shared project guidance and a Claude import" {
  assert_shared_guidance wordpress
}

@test "shell inherits shared project guidance and a Claude import" {
  assert_shared_guidance shell
}

@test "fullstack inherits shared project guidance and a Claude import" {
  assert_shared_guidance fullstack
}
