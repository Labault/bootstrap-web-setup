#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "apply fullstack" "$BS" apply --profile fullstack --target "$p" --skip-bin-check
check "eslint.config.js" "$(exists "$p/eslint.config.js")"
check "husky pre-commit" "$(exists "$p/.husky/pre-commit")"
check "workflow front.yml" "$(exists "$p/.github/workflows/front.yml")"
check "core.hooksPath=.husky" "$([[ "$(git -C "$p" config --get core.hooksPath)" == .husky ]] && echo 1 || echo 0)"
check "suggestion npm" "$(out_has 'npm install -D')"
verdict
