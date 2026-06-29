#!/usr/bin/env bats
load test_helper

@test "reconcile without state dies" {
  run "$BS" reconcile --target "$PROJ"
  [ "$status" -ne 0 ]
  [[ "$output" == *"nothing to reconcile"* ]]
}

@test "clean 3-way merge keeps local edits and the template update, no markers" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf 'disable=SC2034\n' >>"$WORK/templates/common/.shellcheckrc" # B
  sed -i.bak '1s/.*/# my header/' "$PROJ/.shellcheckrc"
  rm -f "$PROJ/.shellcheckrc.bak" # A
  run "$WBS" reconcile --target "$PROJ"
  [ "$status" -eq 0 ]
  [[ "$output" == *"merged cleanly"* ]]
  grep -q '# my header' "$PROJ/.shellcheckrc"    # A kept
  grep -q 'disable=SC2034' "$PROJ/.shellcheckrc" # B applied
  run grep -q '<<<<<<<' "$PROJ/.shellcheckrc"    # no conflict markers
  [ "$status" -ne 0 ]
}

@test "overlapping edits produce a conflict (markers) and exit non-zero" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  sed -i.bak '1s/.*/# from PROJECT/' "$PROJ/.shellcheckrc"
  rm -f "$PROJ/.shellcheckrc.bak"
  sed -i.bak '1s/.*/# from TEMPLATE/' "$WORK/templates/common/.shellcheckrc"
  rm -f "$WORK/templates/common/.shellcheckrc.bak"
  run "$WBS" reconcile --target "$PROJ"
  [ "$status" -ne 0 ]
  grep -q '<<<<<<<' "$PROJ/.shellcheckrc"
}

@test "fast-forward when the file was not edited locally" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf '\n# ff\n' >>"$WORK/templates/common/lychee.toml"
  run "$WBS" reconcile --target "$PROJ"
  [ "$status" -eq 0 ]
  [[ "$output" == *"fast-forward"* ]]
  grep -q '# ff' "$PROJ/lychee.toml"
}

# Fix #1: after a clean reconcile, the state is refreshed so doctor sees no drift.
@test "reconcile refreshes state -> doctor reports no drift afterwards" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf 'disable=SC2034\n' >>"$WORK/templates/common/.shellcheckrc"
  sed -i.bak '1s/.*/# my header/' "$PROJ/.shellcheckrc"
  rm -f "$PROJ/.shellcheckrc.bak"
  "$WBS" reconcile --target "$PROJ" >/dev/null
  run "$WBS" doctor --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [[ "$output" == *"No drift"* ]]
  [[ "$output" == *"local edits kept"* ]]
}

@test "re-running reconcile is a no-op" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  printf 'disable=SC2034\n' >>"$WORK/templates/common/.shellcheckrc"
  sed -i.bak '1s/.*/# my header/' "$PROJ/.shellcheckrc"
  rm -f "$PROJ/.shellcheckrc.bak"
  "$WBS" reconcile --target "$PROJ" >/dev/null
  run "$WBS" reconcile --target "$PROJ"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 merged"* ]]
}

@test "no merge base -> backup + replace fallback" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  sed -i.bak 's/^bootstrap_commit:.*/bootstrap_commit: unknown/' "$PROJ/.bootstrap.yaml"
  rm -f "$PROJ/.bootstrap.yaml.bak"
  echo "# edit" >>"$PROJ/.shellcheckrc"
  run "$BS" reconcile --target "$PROJ"
  [[ "$output" == *"no merge base"* ]]
}
