# shellcheck shell=bash
# File-deposit engine, shared by `apply`. This step (4) covers the "absent file"
# case and --dry-run only. Idempotence, collisions, backups and merges land in
# steps 5-6; this file will grow accordingly.
#
# Depends on lib/common.sh (logging, is_dry_run).

# deposit_file <srcpath> <destpath> <strategy>
# Deposits one file. Prints a single status token to stdout for the caller to
# tally; all human-facing messages go to stderr. Status tokens:
#   created        — file written (or, in dry-run, would be written)
#   skipped-nosrc  — template source missing (not yet authored; dev-time only)
#   exists         — destination already present (collision handling: step 5)
deposit_file() {
  local src="$1" dest="$2" strategy="${3:-replace}"
  local rel="${dest#"$TARGET_DIR"/}"

  # Label suffix shows non-default merge strategies, e.g. ".gitignore [merge-gitignore]".
  local label="$rel"
  [[ "$strategy" != "replace" ]] && label="$rel [$strategy]"

  if [[ ! -f "$src" ]]; then
    log_warn "skip ${rel} — template source not found (${src#"$BOOTSTRAP_ROOT"/})"
    printf 'skipped-nosrc\n'
    return 0
  fi

  if [[ -e "$dest" ]]; then
    # Collision: real handling (identical/backup/merge) arrives in steps 5-6.
    log_info "exists ${rel} — left untouched (collision handling comes in step 5)"
    printf 'exists\n'
    return 0
  fi

  if is_dry_run; then
    log_dry "create ${label}"
    printf 'created\n'
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log_ok "create ${label}"
  printf 'created\n'
}

# run_apply <profile> <target-dir>
# Iterates the profile's resolved file list and deposits each one. Prints a
# summary to stderr. Sets the engine-wide TARGET_DIR used for pretty relative
# paths. Returns 0.
run_apply() {
  local profile="$1"
  TARGET_DIR="$2"

  local src dest strat srcpath destpath status
  local n_created=0 n_exists=0 n_nosrc=0

  while IFS=$'\t' read -r src dest strat; do
    [[ -z "$dest" ]] && continue
    srcpath="$BOOTSTRAP_ROOT/$src"
    destpath="$TARGET_DIR/$dest"
    status="$(deposit_file "$srcpath" "$destpath" "$strat")"
    case "$status" in
      created)       n_created=$((n_created + 1)) ;;
      exists)        n_exists=$((n_exists + 1)) ;;
      skipped-nosrc) n_nosrc=$((n_nosrc + 1)) ;;
    esac
  done < <(resolve_files "$profile")

  printf '\n' >&2
  if is_dry_run; then
    log_info "Dry-run summary: ${n_created} to create, ${n_exists} already present, ${n_nosrc} template(s) not yet authored."
  else
    log_ok "Applied: ${n_created} created, ${n_exists} left untouched, ${n_nosrc} template(s) not yet authored."
  fi
}
