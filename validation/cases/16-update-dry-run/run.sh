#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
(cd "$p" && "$BS" update --dry-run >/dev/null 2>&1 || true)
check "update n'écrit rien dans le projet" "$(dir_only_git "$p")"
verdict
