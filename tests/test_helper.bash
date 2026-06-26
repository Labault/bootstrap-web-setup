# Shared helpers for the bats suite.
# Variables here are consumed by the .bats files that `load` this helper, so
# their use isn't visible when this file is analyzed alone.
# shellcheck disable=SC2034
#
# Resolve the repo root from this file's location.
BOOTSTRAP_REPO="${BOOTSTRAP_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BS="$BOOTSTRAP_REPO/bin/bootstrap"

setup() {
  TESTDIR="$(mktemp -d)"
  export BACKUP_BASE="$TESTDIR/backups"
  PROJ="$TESTDIR/proj"
  mkdir -p "$PROJ"
  git -C "$PROJ" init -q
}

teardown() {
  [ -n "${TESTDIR:-}" ] && rm -rf "$TESTDIR"
}

# make_workcopy: a copy of the repo WITH .git, so reconcile's `git show` (the
# merge base) works and templates can be mutated without touching the real repo.
# Sets WORK and WBS (its bin/bootstrap).
make_workcopy() {
  WORK="$TESTDIR/work"
  mkdir -p "$WORK"
  cp -R "$BOOTSTRAP_REPO/." "$WORK/"
  WBS="$WORK/bin/bootstrap"
}

# apply_minimal <bin> <target>: apply the minimal profile, skipping the binary
# guard (we test logic, not the machine's toolchain).
apply_minimal() {
  "$1" apply --profile minimal --target "$2" --skip-bin-check
}
