#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "apply profil inconnu" "$BS" apply --profile nexistepas --target "$p" --skip-bin-check
check "meurt" "$(exit_nonzero)"
check "message 'Unknown profile'" "$(out_has 'Unknown profile')"
check "rien écrit" "$(absent "$p/.editorconfig")"
verdict
