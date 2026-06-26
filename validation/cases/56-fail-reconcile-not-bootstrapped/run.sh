#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "reconcile sans état" "$BS" reconcile --target "$p"
check "meurt" "$(exit_nonzero)"
check "message 'nothing to reconcile'" "$(out_has 'nothing to reconcile')"
verdict
