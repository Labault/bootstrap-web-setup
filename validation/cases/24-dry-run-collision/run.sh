#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
echo "# mon edit" >> "$p/.shellcheckrc"
run "dry-run sur une collision" "$BS" apply --profile minimal --target "$p" --skip-bin-check --dry-run
check "annonce 'would back up'" "$(out_has 'would back up')"
check "édition toujours là (rien écrit)" "$(file_has "$p/.shellcheckrc" 'mon edit')"
check "aucun backup réel créé" "$(no_backup_for .shellcheckrc)"
verdict
