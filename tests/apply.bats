#!/usr/bin/env bats
load test_helper

@test "dry-run writes nothing" {
  run "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check --dry-run
  [ "$status" -eq 0 ]
  # only .git exists
  run bash -c "ls -A '$PROJ' | grep -v '^.git$' || true"
  [ -z "$output" ]
}

@test "apply deposits files, state and hooks" {
  apply_minimal "$BS" "$PROJ"
  [ -f "$PROJ/.editorconfig" ]
  [ -f "$PROJ/.pre-commit-config.yaml" ]
  [ -f "$PROJ/.bootstrap.yaml" ]
  grep -q '^profile: minimal' "$PROJ/.bootstrap.yaml"
  grep -q '^bootstrap_commit:' "$PROJ/.bootstrap.yaml"
}

@test "apply is idempotent (rerun = no changes)" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  run apply_minimal "$BS" "$PROJ"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 created"* ]]
  [[ "$output" == *"unchanged"* ]]
}

@test "replace collision backs up then overwrites" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  echo "# local edit" >>"$PROJ/.shellcheckrc"
  run apply_minimal "$BS" "$PROJ"
  [[ "$output" == *"replace .shellcheckrc"* ]]
  # original (with the edit) is preserved in a backup
  run bash -c "grep -rl 'local edit' '$BACKUP_BASE'"
  [ "$status" -eq 0 ]
  # destination no longer has the edit
  run grep -q 'local edit' "$PROJ/.shellcheckrc"
  [ "$status" -ne 0 ]
}

@test "--no-overwrite preserves local changes" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  echo "# keep me" >>"$PROJ/.shellcheckrc"
  run "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check --no-overwrite
  [[ "$output" == *"--no-overwrite"* ]]
  grep -q 'keep me' "$PROJ/.shellcheckrc"
}

@test "state records sha256 and tpl_sha256 per file" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  grep -q 'sha256:' "$PROJ/.bootstrap.yaml"
  grep -q 'tpl_sha256:' "$PROJ/.bootstrap.yaml"
}
