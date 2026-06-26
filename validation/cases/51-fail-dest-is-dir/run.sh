#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project); mkdir -p "$p/Makefile"
run "apply dest=dossier" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "échoue" "$(exit_nonzero)"
check "erreur claire" "$(out_has 'a directory exists there')"
verdict
