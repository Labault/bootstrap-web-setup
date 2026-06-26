#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p="$WORK/mon projet"; mkdir -p "$p"; git -C "$p" init -q
run "apply chemin avec espaces" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "déposé malgré les espaces" "$(exists "$p/.editorconfig")"
check "exit 0" "$(exit_is 0)"
verdict
