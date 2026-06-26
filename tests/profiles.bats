#!/usr/bin/env bats
load test_helper

@test "symfony deposits PHP tooling, the php workflow and PHP-aware overrides" {
  echo '{"name":"x/y"}' > "$PROJ/composer.json"
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  [ -f "$PROJ/phpstan.dist.neon" ]
  [ -f "$PROJ/.php-cs-fixer.dist.php" ]
  [ -f "$PROJ/rector.php" ]
  [ -f "$PROJ/.github/workflows/php.yml" ]
  [ -f "$PROJ/.github/workflows/ci.yml" ]          # shared, not replaced
  grep -q 'phpstan' "$PROJ/.pre-commit-config.yaml"
  grep -q 'package-ecosystem: composer' "$PROJ/.github/dependabot.yml"
}

@test "symfony writes a phpstan baseline on an existing project" {
  echo '{"name":"x/y"}' > "$PROJ/composer.json"
  "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check >/dev/null
  [ -f "$PROJ/phpstan-baseline.neon" ]
}

@test "symfony suggests composer dev deps without touching composer.json" {
  echo '{"name":"x/y"}' > "$PROJ/composer.json"
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

@test "fullstack suggests npm deps incl commitlint inherited from minimal" {
  run "$BS" apply --profile fullstack --target "$PROJ" --skip-bin-check
  [[ "$output" == *"npm install -D"* ]]
  [[ "$output" == *"commitlint"* ]]
  [[ "$output" == *"eslint"* ]]
}
