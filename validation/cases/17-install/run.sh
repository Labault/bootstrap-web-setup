#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
bindir="$WORK/bin"
run "install" env BOOTSTRAP_BIN_DIR="$bindir" "$REPO/install.sh"
check "symlink créé" "$([[ -L "$bindir/bootstrap" ]] && echo 1 || echo 0)"
run "appel via symlink" "$bindir/bootstrap" --version
check "appelable" "$(exit_is 0)"
run "ré-install idempotent" env BOOTSTRAP_BIN_DIR="$bindir" "$REPO/install.sh"
check "idempotent" "$(out_has 'already installed')"
verdict
