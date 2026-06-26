#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
run "doctor après apply" "$BS" doctor --target "$p" --skip-bin-check
check "pas de dérive" "$(out_has 'No drift')"
check "exit 0" "$(exit_is 0)"
verdict
