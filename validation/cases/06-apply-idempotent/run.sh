#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
run "re-apply" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "0 créé au re-run" "$(out_has '0 created')"
check "tout 'unchanged'" "$(out_has 'unchanged')"
verdict
