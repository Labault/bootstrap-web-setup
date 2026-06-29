#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
echo "# garder" >>"$p/.shellcheckrc"
run "no-overwrite" "$BS" apply --profile minimal --target "$p" --skip-bin-check --no-overwrite
check "fichier sauté" "$(out_has '--no-overwrite')"
check "édition préservée" "$(file_has "$p/.shellcheckrc" 'garder')"
verdict
