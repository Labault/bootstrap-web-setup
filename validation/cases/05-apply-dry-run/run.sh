#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "dry-run" "$BS" apply --profile minimal --target "$p" --skip-bin-check --dry-run
check "prévisualise la création" "$(out_has 'create .editorconfig')"
check "rien écrit (editorconfig absent)" "$(absent "$p/.editorconfig")"
check "pas d'état" "$(absent "$p/.bootstrap.yaml")"
verdict
