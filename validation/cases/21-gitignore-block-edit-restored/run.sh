#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
echo "/ma-regle-perso/" >>"$p/.gitignore"
sed -i.bak 's#/vendor/#/vendor/\nINJECTE_DANS_BLOC#' "$p/.gitignore"
rm -f "$p/.gitignore.bak"
run "re-apply restaure le bloc" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "injection retirée (bloc restauré)" "$(file_lacks "$p/.gitignore" INJECTE_DANS_BLOC)"
check "ligne user hors-bloc conservée" "$(file_has "$p/.gitignore" '/ma-regle-perso/')"
verdict
