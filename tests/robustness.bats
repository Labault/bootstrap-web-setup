#!/usr/bin/env bats
load test_helper

# C1: a failed write must abort loudly, never report a false success.
@test "read-only target: apply fails loudly and writes no state" {
  if [ "$(id -u)" -eq 0 ]; then skip "root bypasses -w permissions"; fi
  chmod -w "$PROJ"
  run "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check
  chmod +w "$PROJ"   # restore so teardown can clean up
  [ "$status" -ne 0 ]
  [ ! -f "$PROJ/.bootstrap.yaml" ]
}

# C1: a destination that exists as a directory is a clear error, not a half "replace".
@test "dest exists as a directory: clear error" {
  mkdir -p "$PROJ/Makefile"
  run "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check
  [ "$status" -ne 0 ]
  [[ "$output" == *"a directory exists there"* ]]
}

# C2: a lone begin marker must not delete content after it.
@test "gitignore with begin marker but no end marker: no data loss" {
  printf '# user\n# >>> bootstrap\nGARBAGE\nKEEPME\n' > "$PROJ/.gitignore"
  apply_minimal "$BS" "$PROJ" >/dev/null
  grep -q KEEPME "$PROJ/.gitignore"
}

# I1: invalid existing JSON aborts clearly instead of silently doing nothing.
@test "invalid existing extensions.json aborts with a clear message" {
  mkdir -p "$PROJ/.vscode"
  printf '{ broken,,, }' > "$PROJ/.vscode/extensions.json"
  run "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid JSON"* ]]
  [ ! -f "$PROJ/.bootstrap.yaml" ]
}

# I2: reconcile warns on a dirty bootstrap checkout (like apply).
@test "reconcile warns on a dirty bootstrap checkout" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf '\n# dirty\n' >> "$WORK/templates/common/.shellcheckrc"
  echo "# local" >> "$PROJ/.shellcheckrc"
  run "$WBS" reconcile --target "$PROJ"
  [[ "$output" == *"uncommitted changes"* ]]
}

# R5: --profile can't reach outside profiles/.
@test "--profile with a path separator is rejected" {
  run "$BS" apply --profile '../../etc/x' --target "$PROJ" --skip-bin-check
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid profile name"* ]]
}

# R4: a corrupt state file is reported, not read as "everything is new".
@test "corrupt .bootstrap.yaml is reported as unreadable" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  printf 'garbage not yaml @#$\n' > "$PROJ/.bootstrap.yaml"
  run "$BS" doctor --target "$PROJ" --skip-bin-check
  [[ "$output" == *"unreadable"* ]]
}
