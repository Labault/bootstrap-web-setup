#!/usr/bin/env bats
load test_helper

# A project-local analyzer that records any unexpected invocation and replaces
# its baseline, reproducing the destructive effect of automatic regeneration.
prepare_phpstan_probe() {
  echo '{"name":"x/y"}' >"$PROJ/composer.json"
  mkdir -p "$PROJ/vendor/bin"
  cat >"$PROJ/vendor/bin/phpstan" <<'SH'
#!/usr/bin/env bash
printf 'called\n' >phpstan-invoked
printf 'unexpected regeneration\n' >phpstan-baseline.neon
SH
  chmod +x "$PROJ/vendor/bin/phpstan"
}

assert_strict_phpstan_profile() {
  prepare_phpstan_probe
  run "$BS" apply --profile "$1" --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  grep -Eq '^[[:space:]]*level: 9$' "$PROJ/phpstan.dist.neon"
  run grep -q 'phpstan-baseline' "$PROJ/phpstan.dist.neon"
  [ "$status" -eq 1 ]
  [ ! -e "$PROJ/phpstan-baseline.neon" ]
  [ ! -e "$PROJ/phpstan-invoked" ]
}

@test "Symfony deposits level 9 without a baseline or analyzer invocation" {
  assert_strict_phpstan_profile symfony
}

@test "fullstack inherits level 9 without a baseline or analyzer invocation" {
  assert_strict_phpstan_profile fullstack
}

@test "apply preserves an existing project-owned legacy baseline" {
  prepare_phpstan_probe
  printf 'parameters:\n\tignoreErrors: []\n# project-owned legacy debt\n' >"$PROJ/phpstan-baseline.neon"
  cp "$PROJ/phpstan-baseline.neon" "$TESTDIR/expected-baseline"
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check
  [ "$status" -eq 0 ]
  cmp -s "$TESTDIR/expected-baseline" "$PROJ/phpstan-baseline.neon"
  [ ! -e "$PROJ/phpstan-invoked" ]
}

@test "no-overwrite preserves a project's explicit legacy config and baseline" {
  prepare_phpstan_probe
  printf 'includes:\n\t- phpstan-baseline.neon\nparameters:\n\tlevel: 9\n' >"$PROJ/phpstan.dist.neon"
  printf 'parameters:\n\tignoreErrors: []\n# approved legacy debt\n' >"$PROJ/phpstan-baseline.neon"
  cp "$PROJ/phpstan.dist.neon" "$TESTDIR/expected-config"
  cp "$PROJ/phpstan-baseline.neon" "$TESTDIR/expected-baseline"
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check --no-overwrite
  [ "$status" -eq 0 ]
  cmp -s "$TESTDIR/expected-config" "$PROJ/phpstan.dist.neon"
  cmp -s "$TESTDIR/expected-baseline" "$PROJ/phpstan-baseline.neon"
  [ ! -e "$PROJ/phpstan-invoked" ]
}

@test "dry-run creates neither a baseline nor an analyzer invocation" {
  prepare_phpstan_probe
  run "$BS" apply --profile symfony --target "$PROJ" --skip-bin-check --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$PROJ/phpstan.dist.neon" ]
  [ ! -e "$PROJ/phpstan-baseline.neon" ]
  [ ! -e "$PROJ/phpstan-invoked" ]
}

@test "reconcile drops the former default include and preserves the legacy file" {
  WORK="$TESTDIR/bootstrap"
  mkdir -p "$WORK"
  cp -R "$BOOTSTRAP_REPO/bin" "$BOOTSTRAP_REPO/lib" "$BOOTSTRAP_REPO/profiles" \
    "$BOOTSTRAP_REPO/templates" "$BOOTSTRAP_REPO/VERSION" "$WORK/"
  WBS="$WORK/bin/bootstrap"
  git -C "$WORK" init -q
  printf 'includes:\n\t- phpstan-baseline.neon\nparameters:\n\tlevel: 9\n\tpaths:\n\t\t- src\n' \
    >"$WORK/templates/symfony/phpstan.dist.neon"
  git -C "$WORK" add .
  git -C "$WORK" -c user.name='bootstrap test' -c user.email=test@example.com -c commit.gpgsign=false \
    commit -qm 'test fixture: former baseline policy'
  "$WBS" apply --profile symfony --target "$PROJ" --skip-bin-check >/dev/null
  printf 'parameters:\n\tignoreErrors: []\n# preserved legacy debt\n' >"$PROJ/phpstan-baseline.neon"
  cp "$PROJ/phpstan-baseline.neon" "$TESTDIR/expected-baseline"
  cp "$BOOTSTRAP_REPO/templates/symfony/phpstan.dist.neon" "$WORK/templates/symfony/phpstan.dist.neon"
  run "$WBS" reconcile --target "$PROJ"
  [ "$status" -eq 0 ]
  run grep -q 'phpstan-baseline' "$PROJ/phpstan.dist.neon"
  [ "$status" -eq 1 ]
  cmp -s "$TESTDIR/expected-baseline" "$PROJ/phpstan-baseline.neon"
}
