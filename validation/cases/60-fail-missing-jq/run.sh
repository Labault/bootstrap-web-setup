#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
helper="$WORK/bin"
mkdir -p "$helper"
for b in bash git awk grep sed date mktemp dirname basename cp mkdir cat find shasum sha256sum tr; do
  s=$(command -v "$b" 2>/dev/null) && ln -s "$s" "$helper/$b"
done
run "apply sans jq" env PATH="$helper" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "abandonne" "$(exit_nonzero)"
check "mentionne jq" "$(out_has 'jq')"
check "rien écrit (état absent)" "$(absent "$p/.bootstrap.yaml")"
verdict
