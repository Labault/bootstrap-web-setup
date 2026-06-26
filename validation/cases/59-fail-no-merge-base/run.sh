#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
sed -i.bak 's/^bootstrap_commit:.*/bootstrap_commit: unknown/' "$p/.bootstrap.yaml"; rm -f "$p/.bootstrap.yaml.bak"
echo "# edit" >> "$p/.shellcheckrc"
run "reconcile sans base" "$BS" reconcile --target "$p"
check "avertit 'no merge base'" "$(out_has 'no merge base')"
verdict
