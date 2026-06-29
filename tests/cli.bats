#!/usr/bin/env bats
load test_helper

@test "version prints the VERSION file" {
  run "$BS" --version
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$BOOTSTRAP_REPO/VERSION")" ]
}

@test "unknown command exits 2" {
  run "$BS" wat
  [ "$status" -eq 2 ]
}

@test "list shows the four profiles with inheritance" {
  run "$BS" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"minimal"* ]]
  [[ "$output" == *"symfony"* ]]
  [[ "$output" == *"fullstack"* ]]
  [[ "$output" == *"shell"* ]]
  [[ "$output" == *"extends symfony"* ]]
}

@test "detect: empty dir -> minimal" {
  run "$BS" detect --target "$PROJ"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "minimal" ]
}

@test "detect: composer.json -> symfony" {
  echo '{}' >"$PROJ/composer.json"
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "symfony" ]
}

@test "detect: composer.json + package.json -> fullstack" {
  echo '{}' >"$PROJ/composer.json"
  echo '{}' >"$PROJ/package.json"
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "fullstack" ]
}

@test "detect: tracked shell sources -> shell" {
  printf '#!/usr/bin/env bash\n' >"$PROJ/deploy.sh"
  git -C "$PROJ" add deploy.sh
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "shell" ]
}

# Anti-regression: the shell signal is tracked-only, so a stray untracked script
# must NOT flip an otherwise-empty repo off the minimal base.
@test "detect: untracked shell file stays minimal" {
  printf '#!/usr/bin/env bash\n' >"$PROJ/deploy.sh" # never git-added
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "minimal" ]
}

# Anti-regression: composer.json keeps winning even when shell sources exist —
# the web branch is untouched.
@test "detect: composer.json wins over shell sources -> symfony" {
  echo '{}' >"$PROJ/composer.json"
  printf '#!/usr/bin/env bash\n' >"$PROJ/deploy.sh"
  git -C "$PROJ" add composer.json deploy.sh
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "symfony" ]
}

# Anti-regression: a front-only repo (package.json, no composer.json) stays
# minimal even with shell sources — fullstack presupposes PHP, shell excludes it.
@test "detect: front-only repo with shell sources stays minimal" {
  echo '{}' >"$PROJ/package.json"
  printf '#!/usr/bin/env bash\n' >"$PROJ/x.sh"
  git -C "$PROJ" add package.json x.sh
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "minimal" ]
}

@test "detect: unknown --profile exits non-zero" {
  run "$BS" detect --target "$PROJ" --profile wat
  [ "$status" -ne 0 ]
}
