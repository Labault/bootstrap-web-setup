#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
printf '# >>> bootstrap\nGARBAGE\nKEEPME\n' >"$p/.gitignore"
run "apply gitignore corrompu" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "aucune perte de donnée (KEEPME conservé)" "$(file_has "$p/.gitignore" 'KEEPME')"
verdict
