#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
echo "# locale" >>"$p/.shellcheckrc"
run "re-apply sur édition" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "rapporte replace" "$(out_has 'replace .shellcheckrc')"
check "backup créé" "$(backup_for .shellcheckrc)"
check "original (édition) dans le backup" "$(backup_grep locale)"
verdict
