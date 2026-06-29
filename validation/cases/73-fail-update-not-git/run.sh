#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
w="$WORK/repo-nogit"
mkdir -p "$w"
cp -R "$REPO/." "$w/"
rm -rf "$w/.git"
run "update depuis un checkout non-git" "$w/bin/bootstrap" update
check "échoue" "$(exit_nonzero)"
check "message 'not a git checkout'" "$(out_has 'not a git checkout')"
verdict
