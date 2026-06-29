#!/usr/bin/env bats
load test_helper

@test ".gitignore merge keeps user lines and adds a tagged block" {
  printf '# perso\n/mon-dossier/\n' >"$PROJ/.gitignore"
  apply_minimal "$BS" "$PROJ" >/dev/null
  grep -q '/mon-dossier/' "$PROJ/.gitignore"
  grep -q '# >>> bootstrap' "$PROJ/.gitignore"
  grep -q '# <<< bootstrap' "$PROJ/.gitignore"
}

@test ".gitignore merge is idempotent" {
  printf '# perso\n/mon-dossier/\n' >"$PROJ/.gitignore"
  apply_minimal "$BS" "$PROJ" >/dev/null
  run apply_minimal "$BS" "$PROJ"
  [[ "$output" == *"ok .gitignore"* || "$output" == *"unchanged"* ]]
  # exactly one bootstrap block
  run grep -c '# >>> bootstrap' "$PROJ/.gitignore"
  [ "$output" -eq 1 ]
}

@test ".vscode/extensions.json union is deduped and keeps user entries" {
  mkdir -p "$PROJ/.vscode"
  printf '{\n  "recommendations": ["foo.bar", "editorconfig.editorconfig"]\n}\n' >"$PROJ/.vscode/extensions.json"
  apply_minimal "$BS" "$PROJ" >/dev/null
  grep -q 'foo.bar' "$PROJ/.vscode/extensions.json"
  # editorconfig appears exactly once (deduped)
  run grep -c 'editorconfig.editorconfig' "$PROJ/.vscode/extensions.json"
  [ "$output" -eq 1 ]
}
