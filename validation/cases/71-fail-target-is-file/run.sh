#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
f="$WORK/un-fichier"; : > "$f"
run "apply --target un fichier" "$BS" apply --profile minimal --target "$f" --skip-bin-check
check "échoue" "$(exit_nonzero)"
check "message 'not a directory'" "$(out_has 'not a directory')"
verdict
