#!/usr/bin/env bats
load test_helper

@test "symfony deposits PHP tooling, the php workflow and PHP-aware overrides" {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [ -f "$PROJ/phpstan.dist.neon" ]
  [ -f "$PROJ/.php-cs-fixer.dist.php" ]
  [ -f "$PROJ/rector.php" ]
  [ -f "$PROJ/.github/workflows/php.yml" ]
  [ -f "$PROJ/.github/workflows/ci.yml" ] # shared, not replaced
  grep -q 'phpstan' "$PROJ/.pre-commit-config.yaml"
  grep -q 'package-ecosystem: composer' "$PROJ/.github/dependabot.yml"
}

@test "symfony writes a phpstan baseline on an existing project" {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check >/dev/null
  [ -f "$PROJ/phpstan-baseline.neon" ]
}

@test "symfony suggests composer dev deps without touching composer.json" {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check
  [[ "$output" == *"composer require --dev"* ]]
  [[ "$output" == *"phpstan/phpstan"* ]]
  # composer.json is unchanged
  [ "$(cat "$PROJ/composer.json")" = '{"name":"x/y"}' ]
}

@test "fullstack wires Husky as the single git-hook manager" {
  run "$BS" apply --profile fullstack --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [ -f "$PROJ/eslint.config.js" ]
  [ -f "$PROJ/.husky/pre-commit" ]
  [ -f "$PROJ/.github/workflows/front.yml" ]
  [ "$(git -C "$PROJ" config --get core.hooksPath)" = ".husky" ]
}

@test "fullstack suggests front npm deps (eslint/prettier/husky)" {
  run "$BS" apply --profile fullstack --target "$PROJ" --skip-bin-check
  [[ "$output" == *"npm install -D"* ]]
  [[ "$output" == *"eslint"* ]]
  [[ "$output" == *"husky"* ]]
}

@test "no profile deposits commitlint config (replaced by a shell linter)" {
  run "$BS" apply --profile fullstack --target "$PROJ" --skip-bin-check
  [ ! -e "$PROJ/commitlint.config.cjs" ]
  [ -f "$PROJ/scripts/lint-commit-msg.sh" ]
}

@test "shell extends minimal (list shows the edge and the added binaries)" {
  run "$BS" list
  [ "$status" -eq 0 ]
  # the shell stanza, specifically, inherits minimal
  echo "$output" | grep -Eq '^shell .*\(extends minimal\)'
  # bats + shfmt are added; shellcheck stays inherited (not redeclared)
  [[ "$output" == *"bats"* ]]
  [[ "$output" == *"shfmt"* ]]
}

@test "shell deposits the bats harness, the tests workflow and shell-aware overrides" {
  run "$BS" apply --profile shell --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  # inherited minimal base (proves resolution down the chain)
  [ -f "$PROJ/.editorconfig" ]
  [ -f "$PROJ/scripts/lint-commit-msg.sh" ]
  [ -f "$PROJ/.github/workflows/ci.yml" ] # shared, not replaced
  # shell additions
  [ -f "$PROJ/tests/smoke.bats" ]
  [ -f "$PROJ/tests/test_helper.bash" ]
  [ -f "$PROJ/.github/workflows/tests.yml" ]
  grep -q 'shfmt' "$PROJ/.pre-commit-config.yaml"
  grep -q 'bats tests/' "$PROJ/Makefile"
}

@test "shell: the deposited bats skeleton passes immediately" {
  "$BS" apply --profile shell --target "$PROJ" --skip-bin-check >/dev/null
  run bats "$PROJ/tests/"
  [ "$status" -eq 0 ]
}

@test "wordpress extends minimal and deposits WordPress quality tooling" {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  run "$BS" apply --profile wordpress --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [ -f "$PROJ/phpcs.xml.dist" ]
  [ -f "$PROJ/phpstan.dist.neon" ]
  [ -f "$PROJ/rector.php" ]
  [ ! -f "$PROJ/phpstan-baseline.neon" ]
  [ -f "$PROJ/.github/workflows/wordpress.yml" ]
  [ -f "$PROJ/.github/workflows/ci.yml" ]
  awk '
    /^\[\*\.php\]$/ { in_php = 1; next }
    in_php && /^\[/ { exit }
    in_php && /^indent_style = tab$/ { found = 1 }
    END { exit !found }
  ' "$PROJ/.editorconfig"
  grep -q 'WordPress' "$PROJ/phpcs.xml.dist"
  grep -q 'PHPCompatibilityWP' "$PROJ/phpcs.xml.dist"
  grep -Fq 'type="relative">^wp-[^/]+\.php$' "$PROJ/phpcs.xml.dist"
  grep -Fq 'ref="WordPress.Files.FileName"' "$PROJ/phpcs.xml.dist"
  grep -Fq '<exclude name="WordPress.Files.FileName"/>' "$PROJ/phpcs.xml.dist"
  grep -Fq 'type="relative">^tests/' "$PROJ/phpcs.xml.dist"
  run grep -Fq '<exclude-pattern>/wp-*.php</exclude-pattern>' "$PROJ/phpcs.xml.dist"
  [ "$status" -ne 0 ]
  grep -q 'phpstan-phpunit/extension.neon' "$PROJ/phpstan.dist.neon"
  grep -q 'phpstan-phpunit/rules.neon' "$PROJ/phpstan.dist.neon"
  grep -q 'vendor/phpunit/phpunit/src/Framework/Assert.php' "$PROJ/phpstan.dist.neon"
  grep -Fq 'wp-settings.php (?)' "$PROJ/phpstan.dist.neon"
  run grep -Fq -- '- wp-*.php' "$PROJ/phpstan.dist.neon"
  [ "$status" -ne 0 ]
  grep -q "__DIR__ . '/wp-settings.php'" "$PROJ/rector.php"
  run grep -Fq "__DIR__ . '/wp-*.php'" "$PROJ/rector.php"
  [ "$status" -ne 0 ]
  grep -q 'phpcs' "$PROJ/.pre-commit-config.yaml"
  grep -q 'rector' "$PROJ/.pre-commit-config.yaml"
  grep -q 'package-ecosystem: composer' "$PROJ/.github/dependabot.yml"
  grep -q 'vendor/bin/phpcbf' "$PROJ/Makefile"
  grep -q 'vendor/bin/rector' "$PROJ/Makefile"
}

@test "wordpress suggests its Composer quality tools without changing composer.json" {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  run "$BS" apply --profile wordpress --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true"* ]]
  [[ "$output" == *"composer require --dev"* ]]
  [[ "$output" == *"wp-coding-standards/wpcs"* ]]
  [[ "$output" == *"phpcompatibility/phpcompatibility-wp"* ]]
  [[ "$output" == *"phpstan/phpstan-phpunit"* ]]
  [[ "$output" == *"phpunit/phpunit"* ]]
  [[ "$output" == *"rector/rector"* ]]
  [[ "$output" == *"szepeviktor/phpstan-wordpress"* ]]
  [ "$(cat "$PROJ/composer.json")" = '{"name":"x/y"}' ]
}
