#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
WBS=$(workcopy); p=$(new_project)
"$WBS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
sed -i.bak '1s/.*/# depuis PROJET/' "$p/.shellcheckrc"; rm -f "$p/.shellcheckrc.bak"
sed -i.bak '1s/.*/# depuis TEMPLATE/' "$WORK/repo/templates/common/.shellcheckrc"; rm -f "$WORK/repo/templates/common/.shellcheckrc.bak"
run "reconcile en conflit" "$WBS" reconcile --target "$p"
check "exit != 0 (conflit)" "$(exit_nonzero)"
check "marqueurs de conflit écrits" "$(file_has "$p/.shellcheckrc" '<<<<<<<')"
verdict
