#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
run "doctor minimal" "$BS" doctor --profile minimal --skip-bin-check
check "vérifie les binaires requis" "$(out_has 'required binaries')"
check "exit 0 avec --skip-bin-check" "$(exit_is 0)"
verdict
