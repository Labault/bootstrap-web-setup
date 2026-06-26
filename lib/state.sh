# shellcheck shell=bash
# Writes .bootstrap.yaml — the state file that records what `apply` deposited
# (§4.2, §9.4, §10). It is the single trace that unlocks Phase 2 drift detection.
# Written by `apply` only (never in dry-run); read later by `doctor`. Hand-edits
# are not expected. We emit YAML by hand (no yq dependency) in a shape our own
# awk parser can read back. STATE_FILE_NAME is defined in lib/common.sh.

# write_bootstrap_state <target> <profile>
# Consumes the MANAGED_FILES array (entries: "<relpath>\t<strategy>") populated
# by run_apply, hashes each deposited file and writes the state file.
write_bootstrap_state() {
  local target="$1" profile="$2"
  local statefile="$target/$STATE_FILE_NAME"
  local version applied_at commit
  version="$(bootstrap_version)"
  applied_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # The bootstrap repo commit at apply time — lets `reconcile` retrieve the base
  # template (O) via `git show <commit>:...` for a 3-way merge (Phase 3).
  commit="$(git -C "$BOOTSTRAP_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"

  local tmp; tmp="$(mktemp)"
  {
    printf '# Managed by bootstrap — do not edit by hand.\n'
    # Literal backticks in a comment; nothing to expand.
    # shellcheck disable=SC2016
    printf '# Written by `bootstrap apply`; read by `bootstrap doctor` (Phase 2).\n'
    printf 'profile: %s\n' "$profile"
    printf 'bootstrap_version: %s\n' "$version"
    printf 'bootstrap_commit: %s\n' "$commit"
    printf 'applied_at: %s\n' "$applied_at"
    printf 'files:\n'
    local entry rel strat src hash tpl
    for entry in ${MANAGED_FILES[@]+"${MANAGED_FILES[@]}"}; do
      IFS=$'\t' read -r rel strat src <<< "$entry"
      hash="$(file_sha256 "$target/$rel")"
      # tpl_sha256 = hash of the template source at deposit time. Lets `doctor`
      # tell "template changed" (behind) from "local edits preserved" (customized).
      tpl=""
      [[ -n "$src" && -f "$BOOTSTRAP_ROOT/$src" ]] && tpl="$(file_sha256 "$BOOTSTRAP_ROOT/$src")"
      printf '  - path: %s\n' "$rel"
      printf '    sha256: %s\n' "$hash"
      if [[ -n "$tpl" ]]; then
        printf '    tpl_sha256: %s\n' "$tpl"
      fi
      # Use a full `if` (not `[[ … ]] && …`): as the loop's last statement, a
      # false test would make the function return 1 and trip `set -e`.
      if [[ "$strat" != "replace" ]]; then
        printf '    strategy: %s\n' "$strat"
      fi
    done
  } > "$tmp"

  # Idempotence: if only applied_at would change (everything else identical), keep
  # the existing file so re-applying an unchanged project produces no git diff.
  local new_body cur_body
  new_body="$(grep -v '^applied_at:' "$tmp")"
  if [[ -f "$statefile" ]]; then
    cur_body="$(grep -v '^applied_at:' "$statefile")"
    if [[ "$cur_body" == "$new_body" ]]; then
      rm -f "$tmp"
      return 0
    fi
  fi
  mv "$tmp" "$statefile"
}
