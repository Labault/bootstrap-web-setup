#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
echo "# edit" >> "$p/Makefile"
run "doctor --strict sur dérive" "$BS" doctor --target "$p" --skip-bin-check --strict
check "exit != 0 (strict + dérive)" "$(exit_nonzero)"
check "mentionne la dérive" "$(out_has 'Drift')"
verdict
