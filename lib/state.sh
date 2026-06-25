# shellcheck shell=bash
# Writes .bootstrap.yaml — the state file that records what `apply` deposited
# (§4.2, §9.4, §10). It is the single trace that unlocks Phase 2 drift detection.
# Written by `apply` only (never in dry-run); read later by `doctor`. Hand-edits
# are not expected. We emit YAML by hand (no yq dependency) in a shape our own
# awk parser can read back.

STATE_FILE_NAME=".bootstrap.yaml"

# write_bootstrap_state <target> <profile>
# Consumes the MANAGED_FILES array (entries: "<relpath>\t<strategy>") populated
# by run_apply, hashes each deposited file and writes the state file.
write_bootstrap_state() {
  local target="$1" profile="$2"
  local statefile="$target/$STATE_FILE_NAME"
  local version applied_at
  version="$(bootstrap_version)"
  applied_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  {
    printf '# Managed by bootstrap — do not edit by hand.\n'
    # Literal backticks in a comment; nothing to expand.
    # shellcheck disable=SC2016
    printf '# Written by `bootstrap apply`; read by `bootstrap doctor` (Phase 2).\n'
    printf 'profile: %s\n' "$profile"
    printf 'bootstrap_version: %s\n' "$version"
    printf 'applied_at: %s\n' "$applied_at"
    printf 'files:\n'
    local entry rel strat hash
    for entry in ${MANAGED_FILES[@]+"${MANAGED_FILES[@]}"}; do
      rel="${entry%%$'\t'*}"
      strat="${entry#*$'\t'}"
      hash="$(file_sha256 "$target/$rel")"
      printf '  - path: %s\n' "$rel"
      printf '    sha256: %s\n' "$hash"
      # Use a full `if` (not `[[ … ]] && …`): as the loop's last statement, a
      # false test would make the function return 1 and trip `set -e`.
      if [[ "$strat" != "replace" ]]; then
        printf '    strategy: %s\n' "$strat"
      fi
    done
  } > "$statefile"
}
