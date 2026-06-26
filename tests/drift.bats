#!/usr/bin/env bats
load test_helper

@test "doctor on a fresh apply reports no drift" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  run "$BS" doctor --target "$PROJ"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No drift"* ]]
}

@test "doctor without state skips the drift check" {
  run "$BS" doctor --target "$PROJ" --profile minimal
  [[ "$output" == *"Drift check skipped"* ]]
}

@test "locally modified file is reported and --strict exits non-zero" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  echo "# edit" >> "$PROJ/Makefile"
  run "$BS" doctor --target "$PROJ"
  [ "$status" -eq 0 ]                       # informational by default
  [[ "$output" == *"Makefile"* && "$output" == *"modified locally"* ]]
  run "$BS" doctor --target "$PROJ" --strict
  [ "$status" -ne 0 ]                       # strict mode flags drift
}

@test "missing file is reported" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  rm "$PROJ/CLAUDE.md"
  run "$BS" doctor --target "$PROJ"
  [[ "$output" == *"CLAUDE.md"* && "$output" == *"missing"* ]]
}

@test "an updated template shows the file as behind" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf '\n# evolved\n' >> "$WORK/templates/common/lychee.toml"
  run "$WBS" doctor --target "$PROJ"
  [[ "$output" == *"lychee.toml"* && "$output" == *"template updated"* ]]
}
