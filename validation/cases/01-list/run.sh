#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
run "list" "$BS" list
check "3 profils listés (fullstack présent)" "$(out_has 'fullstack')"
check "héritage affiché" "$(out_has 'extends symfony')"
check "exit 0" "$(exit_is 0)"
verdict
