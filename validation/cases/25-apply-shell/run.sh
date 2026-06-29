#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
printf '#!/usr/bin/env bash\necho hi\n' >"$p/deploy.sh"
git -C "$p" add deploy.sh
run "apply shell" "$BS" apply --profile shell --target "$p" --skip-bin-check
check "tests/smoke.bats déposé" "$(exists "$p/tests/smoke.bats")"
check "tests/test_helper.bash déposé" "$(exists "$p/tests/test_helper.bash")"
check "workflow tests.yml ajouté" "$(exists "$p/.github/workflows/tests.yml")"
check "ci.yml conservé (pas écrasé)" "$(exists "$p/.github/workflows/ci.yml")"
check "shfmt dans .pre-commit-config.yaml" "$(file_has "$p/.pre-commit-config.yaml" 'shfmt')"
check "cible make test (bats)" "$(file_has "$p/Makefile" 'bats tests/')"
check "base minimal héritée (.editorconfig)" "$(exists "$p/.editorconfig")"
verdict
