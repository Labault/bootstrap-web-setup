#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "detect vide" "$BS" detect --target "$p"
check "vide -> minimal" "$(out_has 'minimal')"
echo '{}' >"$p/composer.json"
run "detect composer" "$BS" detect --target "$p"
check "composer.json -> symfony" "$(out_has 'symfony')"
echo '{}' >"$p/package.json"
run "detect package" "$BS" detect --target "$p"
check "+package.json -> fullstack" "$(out_has 'fullstack')"
# Shell signal: a tooling repo tracks *.sh but carries no composer/package
# manifest. Use a fresh project (name free of the word "shell" to avoid a
# false-positive substring match on the printed target path).
t=$(new_project toolkit)
printf '#!/usr/bin/env bash\n' >"$t/deploy.sh"
git -C "$t" add deploy.sh
run "detect shell" "$BS" detect --target "$t"
check "tracked *.sh (no manifest) -> shell" "$(out_has 'shell')"
verdict
