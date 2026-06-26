#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
"$BS" apply --profile minimal --target "$p" --skip-bin-check >/dev/null 2>&1
run "upgrade minimal -> symfony" "$BS" apply --profile symfony --target "$p" --skip-bin-check
check "PHP ajouté (phpstan.dist.neon)" "$(exists "$p/phpstan.dist.neon")"
check "pre-commit gagne les hooks PHP" "$(file_has "$p/.pre-commit-config.yaml" 'phpstan')"
check "état passe à symfony" "$(file_has "$p/.bootstrap.yaml" 'profile: symfony')"
verdict
