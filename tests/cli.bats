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

@test "list shows the three profiles with inheritance" {
  run "$BS" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"minimal"* ]]
  [[ "$output" == *"symfony"*  ]]
  [[ "$output" == *"fullstack"* ]]
  [[ "$output" == *"extends symfony"* ]]
}

@test "detect: empty dir -> minimal" {
  run "$BS" detect --target "$PROJ"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "minimal" ]
}

@test "detect: composer.json -> symfony" {
  echo '{}' > "$PROJ/composer.json"
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "symfony" ]
}

@test "detect: composer.json + package.json -> fullstack" {
  echo '{}' > "$PROJ/composer.json"
  echo '{}' > "$PROJ/package.json"
  run "$BS" detect --target "$PROJ"
  [ "${lines[-1]}" = "fullstack" ]
}

@test "detect: unknown --profile exits non-zero" {
  run "$BS" detect --target "$PROJ" --profile wat
  [ "$status" -ne 0 ]
}
