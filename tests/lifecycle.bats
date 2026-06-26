#!/usr/bin/env bats
load test_helper

# Fix B: re-applying an unchanged project must not rewrite the state (applied_at
# is preserved when nothing else changed) -> no spurious git diff.
@test "re-apply of an unchanged project leaves .bootstrap.yaml byte-identical" {
  apply_minimal "$BS" "$PROJ" >/dev/null
  h1="$(shasum "$PROJ/.bootstrap.yaml" | awk '{print $1}')"
  apply_minimal "$BS" "$PROJ" >/dev/null
  h2="$(shasum "$PROJ/.bootstrap.yaml" | awk '{print $1}')"
  [ "$h1" = "$h2" ]
}

# Fix A: reconcile must write the state in the same deterministic order as apply.
@test "reconcile writes state in the same stable order as apply" {
  make_workcopy
  apply_minimal "$WBS" "$PROJ" >/dev/null
  ord1="$(grep 'path:' "$PROJ/.bootstrap.yaml")"
  printf 'disable=SC2034\n' >> "$WORK/templates/common/.shellcheckrc"
  sed -i.bak '1s/.*/# h/' "$PROJ/.shellcheckrc"; rm -f "$PROJ/.shellcheckrc.bak"
  "$WBS" reconcile --target "$PROJ" >/dev/null
  ord2="$(grep 'path:' "$PROJ/.bootstrap.yaml")"
  [ "$ord1" = "$ord2" ]
}

# Fix C: applying from a dirty bootstrap checkout warns about the base mismatch.
@test "apply from a dirty bootstrap checkout warns" {
  make_workcopy
  printf '\n# uncommitted\n' >> "$WORK/templates/common/lychee.toml"
  run apply_minimal "$WBS" "$PROJ"
  [[ "$output" == *"uncommitted changes"* ]]
}

# Fix D: an unknown parent profile aborts at the top level (die propagates) and
# deposits nothing.
@test "a profile with an unknown parent aborts and writes nothing" {
  make_workcopy
  printf 'extends: nope\n' > "$WORK/profiles/_brokentest.yaml"
  run "$WBS" apply --profile _brokentest --target "$PROJ" --skip-bin-check
  [ "$status" -ne 0 ]
  run bash -c "ls -A '$PROJ' | grep -v '^.git$' || true"
  [ -z "$output" ]
}

@test "update --dry-run never writes to the current directory" {
  # update operates on the bootstrap checkout, not cwd; don't assert its own exit
  # (it does a network fetch), only that the project dir is untouched.
  ( cd "$PROJ" && "$BS" update --dry-run >/dev/null 2>&1 || true )
  run bash -c "ls -A '$PROJ' | grep -v '^.git$' || true"
  [ -z "$output" ]
}

@test "install.sh symlinks the CLI and is idempotent" {
  bindir="$TESTDIR/bin"
  run env BOOTSTRAP_BIN_DIR="$bindir" "$BOOTSTRAP_REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -L "$bindir/bootstrap" ]
  run "$bindir/bootstrap" --version
  [ "$status" -eq 0 ]
  run env BOOTSTRAP_BIN_DIR="$bindir" "$BOOTSTRAP_REPO/install.sh"
  [[ "$output" == *"already installed"* ]]
}
