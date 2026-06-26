#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
run "apply --target inexistant" "$BS" apply --profile minimal --target "$WORK/nexistepas" --skip-bin-check
check "échoue" "$(exit_nonzero)"
check "message 'not a directory'" "$(out_has 'not a directory')"
verdict
