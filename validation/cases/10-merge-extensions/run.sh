#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project); mkdir -p "$p/.vscode"
printf '{ "recommendations": ["foo.bar","editorconfig.editorconfig"] }' > "$p/.vscode/extensions.json"
run "merge extensions" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "reco utilisateur conservée" "$(file_has "$p/.vscode/extensions.json" 'foo.bar')"
check "editorconfig dédupliqué" "$([[ "$(grep -c 'editorconfig.editorconfig' "$p/.vscode/extensions.json")" == 1 ]] && echo 1 || echo 0)"
verdict
