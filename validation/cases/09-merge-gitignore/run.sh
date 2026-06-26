#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
printf '# mine\n/secret/\n' > "$p/.gitignore"
run "merge gitignore" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "ligne utilisateur conservée" "$(file_has "$p/.gitignore" '/secret/')"
check "bloc bootstrap ajouté" "$(file_has "$p/.gitignore" '>>> bootstrap')"
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
check "un seul bloc (idempotent)" "$([[ "$(grep -c '>>> bootstrap' "$p/.gitignore")" == 1 ]] && echo 1 || echo 0)"
verdict
