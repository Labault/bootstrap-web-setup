#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
WBS=$(workcopy); p=$(new_project)
"$WBS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
printf '\n# ff\n' >> "$WORK/repo/templates/common/lychee.toml"
run "reconcile ff" "$WBS" reconcile --target "$p"
check "fast-forward" "$(out_has 'fast-forward')"
check "changement du template appliqué" "$(file_has "$p/lychee.toml" '# ff')"
verdict
