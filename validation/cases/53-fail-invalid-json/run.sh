#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project); mkdir -p "$p/.vscode"
printf '{ broken,,,' > "$p/.vscode/extensions.json"
run "apply json invalide" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "abandonne" "$(exit_nonzero)"
check "message clair 'invalid JSON'" "$(out_has 'invalid JSON')"
check "pas d'état partiel" "$(absent "$p/.bootstrap.yaml")"
verdict
