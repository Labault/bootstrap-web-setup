#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
chmod -w "$p"
run "apply sur cible read-only" "$BS" apply --profile minimal --target "$p" --skip-bin-check
chmod +w "$p"
check "échoue (exit != 0)" "$(exit_nonzero)"
check "pas de faux succès (état absent)" "$(absent "$p/.bootstrap.yaml")"
verdict
