# shellcheck shell=bash
# Merge strategies for collision-tolerant files (§9.3). Each renderer prints the
# full desired destination content to stdout; the deposit engine decides whether
# that differs from what's on disk and whether to back up + write.

GITIGNORE_BEGIN="# >>> bootstrap"
GITIGNORE_END="# <<< bootstrap"

# render_gitignore <dest> <src>
# Prints the .gitignore the project should have: the user's own lines untouched,
# with bootstrap's managed entries kept inside a tagged block. Idempotent — an
# existing block is replaced in place; otherwise the block is appended.
render_gitignore() {
  local dest="$1" src="$2"
  local section
  section="$GITIGNORE_BEGIN"$'\n'
  section+="# Managed by bootstrap — do not edit inside this block."$'\n'
  section+="# Re-run 'bootstrap apply' to update it."$'\n'
  section+="$(cat "$src")"$'\n'
  section+="$GITIGNORE_END"

  if [[ ! -s "$dest" ]]; then
    printf '%s\n' "$section"
    return 0
  fi

  if grep -qxF "$GITIGNORE_BEGIN" "$dest"; then
    # Replace the existing block in place. The section is fed through a file and
    # read with getline rather than passed via -v: BSD awk (macOS default)
    # rejects newlines in -v assignments.
    local secfile; secfile="$(mktemp)"
    printf '%s\n' "$section" > "$secfile"
    awk -v b="$GITIGNORE_BEGIN" -v e="$GITIGNORE_END" -v secfile="$secfile" '
      $0 == b { while ((getline line < secfile) > 0) print line; close(secfile); skip = 1; next }
      skip && $0 == e { skip = 0; next }
      skip { next }
      { print }
    ' "$dest"
    rm -f "$secfile"
  else
    # Append, separated by a blank line, preserving the user's content as-is.
    cat "$dest"
    [[ -n "$(tail -c1 "$dest")" ]] && printf '\n'
    printf '\n%s\n' "$section"
  fi
}

# render_extensions_json <dest> <src>
# Prints a merged .vscode/extensions.json: union (deduped) of the existing and
# template `recommendations` (and `unwantedRecommendations`), other keys kept.
render_extensions_json() {
  local dest="$1" src="$2"
  require_cmd jq
  if [[ ! -s "$dest" ]]; then
    jq . "$src"
    return 0
  fi
  jq -s '
    (.[0] // {}) as $cur | (.[1] // {}) as $tpl |
    ($cur * $tpl)
    | .recommendations =
        (((($cur.recommendations // []) + ($tpl.recommendations // [])) | unique))
    | if (($cur.unwantedRecommendations // []) + ($tpl.unwantedRecommendations // [])) | length > 0
      then .unwantedRecommendations =
        ((($cur.unwantedRecommendations // []) + ($tpl.unwantedRecommendations // [])) | unique)
      else . end
  ' "$dest" "$src"
}

# canonical_json <file-or-"-">  -> stable, sorted-key JSON for comparison.
canonical_json() {
  jq -S -c . "$1"
}
