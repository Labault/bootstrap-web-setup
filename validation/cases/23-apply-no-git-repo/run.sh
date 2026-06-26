#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p="$WORK/nogit"; mkdir -p "$p"
run "apply sur dossier NON-git" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "fichiers déposés quand même" "$(exists "$p/.editorconfig")"
check "hooks sautés (pas un repo git)" "$(out_has 'not a git repository')"
check "exit 0" "$(exit_is 0)"
verdict
