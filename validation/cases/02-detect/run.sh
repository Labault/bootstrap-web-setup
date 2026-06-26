#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "detect vide" "$BS" detect --target "$p"
check "vide -> minimal" "$(out_has 'minimal')"
echo '{}' > "$p/composer.json"
run "detect composer" "$BS" detect --target "$p"
check "composer.json -> symfony" "$(out_has 'symfony')"
echo '{}' > "$p/package.json"
run "detect package" "$BS" detect --target "$p"
check "+package.json -> fullstack" "$(out_has 'fullstack')"
verdict
