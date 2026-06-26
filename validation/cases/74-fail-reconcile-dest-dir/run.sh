#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
rm "$p/.shellcheckrc"; mkdir "$p/.shellcheckrc"
run "reconcile avec un fichier tracké devenu dossier" "$BS" reconcile --target "$p"
check "échoue" "$(exit_nonzero)"
check "erreur claire 'a directory exists'" "$(out_has 'a directory exists there')"
verdict
