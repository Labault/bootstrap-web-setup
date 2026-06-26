#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "apply profil traversal" "$BS" apply --profile '../../etc/x' --target "$p" --skip-bin-check
check "rejeté" "$(exit_nonzero)"
check "message 'Invalid profile name'" "$(out_has 'Invalid profile name')"
verdict
