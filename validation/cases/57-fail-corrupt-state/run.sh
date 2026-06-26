#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
printf 'garbage @#$\n' > "$p/.bootstrap.yaml"
run "doctor état corrompu" "$BS" doctor --target "$p" --skip-bin-check
check "signale 'unreadable'" "$(out_has 'unreadable')"
verdict
