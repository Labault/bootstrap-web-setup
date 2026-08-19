#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
echo '{"name":"x/y"}' >"$p/composer.json"
run "apply wordpress" "$BS" apply --profile wordpress --target "$p" --skip-bin-check
check "phpcs.xml.dist" "$(exists "$p/phpcs.xml.dist")"
check "phpstan.dist.neon" "$(exists "$p/phpstan.dist.neon")"
check "workflow wordpress.yml ajouté" "$(exists "$p/.github/workflows/wordpress.yml")"
check "ci.yml conservé (pas écrasé)" "$(exists "$p/.github/workflows/ci.yml")"
check "baseline phpstan absente en mode strict" "$(absent "$p/phpstan-baseline.neon")"
check "WordPress Coding Standards configuré" "$(file_has "$p/phpcs.xml.dist" 'WordPress')"
check "compatibilité PHP WordPress configurée" "$(file_has "$p/phpcs.xml.dist" 'PHPCompatibilityWP')"
check "Rector configuré" "$(exists "$p/rector.php")"
check "indentation PHP par tabulations" "$(file_has "$p/.editorconfig" 'indent_style = tab')"
check "autorisation du plugin Composer suggérée" "$(out_has 'allow-plugins.dealerdirect/phpcodesniffer-composer-installer')"
check "dépendances Composer suggérées" "$(out_has 'wp-coding-standards/wpcs')"
verdict
