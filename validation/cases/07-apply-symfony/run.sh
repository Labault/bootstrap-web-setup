#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
echo '{"name":"x/y"}' > "$p/composer.json"
run "apply symfony" "$BS" apply --profile symfony --target "$p" --skip-bin-check
check "phpstan.dist.neon" "$(exists "$p/phpstan.dist.neon")"
check "rector.php" "$(exists "$p/rector.php")"
check "workflow php.yml ajouté" "$(exists "$p/.github/workflows/php.yml")"
check "ci.yml conservé (pas écrasé)" "$(exists "$p/.github/workflows/ci.yml")"
check "baseline phpstan créée" "$(exists "$p/phpstan-baseline.neon")"
check "suggestion composer" "$(out_has 'composer require --dev')"
verdict
