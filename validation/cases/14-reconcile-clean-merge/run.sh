#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
WBS=$(workcopy)
p=$(new_project)
"$WBS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
printf 'disable=SC2034\n' >> "$WORK/repo/templates/common/.shellcheckrc"
sed -i.bak '1s/.*/# mon en-tete/' "$p/.shellcheckrc"; rm -f "$p/.shellcheckrc.bak"
run "reconcile" "$WBS" reconcile --target "$p"
check "merge propre" "$(out_has 'merged cleanly')"
check "édition locale conservée" "$(file_has "$p/.shellcheckrc" 'mon en-tete')"
check "MAJ du template appliquée" "$(file_has "$p/.shellcheckrc" 'disable=SC2034')"
check "aucun marqueur de conflit" "$(file_lacks "$p/.shellcheckrc" '<<<<<<')"
verdict
