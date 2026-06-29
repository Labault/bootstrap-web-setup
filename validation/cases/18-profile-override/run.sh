#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
echo '{"name":"x/y"}' >"$p/composer.json"
run "apply --profile minimal (force malgré composer.json)" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "minimal déposé" "$(exists "$p/.editorconfig")"
check "PAS de phpstan (override respecté)" "$(absent "$p/phpstan.dist.neon")"
check "état = minimal" "$(file_has "$p/.bootstrap.yaml" 'profile: minimal')"
verdict
