#!/usr/bin/env bats
load test_helper

# Fix #2/#3: a missing jq must abort apply BEFORE writing anything — not corrupt
# a half-deposited project from inside a $() subshell.
@test "apply without jq aborts cleanly and writes nothing" {
  helper="$TESTDIR/helperbin"
  mkdir -p "$helper"
  for b in bash git awk grep sed date mktemp dirname basename cp mkdir cat find shasum pre-commit rev tr; do
    src="$(command -v "$b" 2>/dev/null)" && ln -s "$src" "$helper/$b"
  done
  run env PATH="$helper" "$BS" apply --profile minimal --target "$PROJ" --skip-bin-check
  [ "$status" -ne 0 ]
  [[ "$output" == *"jq"* ]]
  # nothing deposited (only .git remains)
  run bash -c "ls -A '$PROJ' | grep -v '^.git$' || true"
  [ -z "$output" ]
}

@test "bash < 4 is rejected with a clear message" {
  if [ ! -x /bin/bash ]; then skip "no system bash"; fi
  run /bin/bash "$BS" --version
  # macOS /bin/bash is 3.2 -> guard fires; a modern /bin/bash would pass (skip then)
  if [ "$status" -eq 0 ]; then skip "/bin/bash is already 4+"; fi
  [ "$status" -ne 0 ]
  [[ "$output" == *"bash 4+"* ]]
}
