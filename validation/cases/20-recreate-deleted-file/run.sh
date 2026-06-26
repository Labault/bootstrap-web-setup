#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
rm "$p/CLAUDE.md"
run "re-apply après suppression" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "fichier recréé" "$(exists "$p/CLAUDE.md")"
check "rapporte 1 created" "$(out_has '1 created')"
verdict
