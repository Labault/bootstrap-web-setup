# shellcheck shell=bash
# File-deposit engine, shared by `apply`.
#
# Step 4 added the absent-file case + --dry-run.
# Step 5 adds idempotence and collision handling for `replace` files:
#   - destination identical to template  -> no-op (idempotence)
#   - destination differs                -> backup then replace
#                                           (or skip if --no-overwrite)
# Merge-strategy files (.gitignore, extensions.json) that already exist and
# differ are deferred to step 6; until then they report `merge-pending`.
#
# Depends on lib/common.sh (logging, is_dry_run).

# Where backups go (§9.5). One subfolder per apply run, created lazily on first
# backup so runs that overwrite nothing leave no empty directories behind.
BACKUP_BASE="${BACKUP_BASE:-$HOME/Documents/Backups/bootstrap}"
NO_OVERWRITE="${NO_OVERWRITE:-0}"

# backup_file <destpath>
# Copies an existing destination into the run's backup dir, preserving its path
# relative to the target project. Echoes the backup path on stdout.
backup_file() {
  local dest="$1"
  local rel="${dest#"$TARGET_DIR"/}"
  local bpath="$BACKUP_RUN_DIR/$rel"
  mkdir -p "$(dirname "$bpath")"
  cp -p "$dest" "$bpath"
  printf '%s\n' "$bpath"
}

# deposit_file <srcpath> <destpath> <strategy>
# Deposits one file and prints a single status token to stdout for tallying.
# Status tokens:
#   created            — written (or, in dry-run, would be written)
#   identical          — already matches the template (no-op)
#   replaced           — backed up then overwritten (or would be, in dry-run)
#   skipped-nooverwrite— differs but --no-overwrite is set
#   merge-pending      — merge-strategy file differs (handled in step 6)
#   skipped-nosrc      — template source not yet authored (dev-time only)
deposit_file() {
  local src="$1" dest="$2" strategy="${3:-replace}"
  local rel="${dest#"$TARGET_DIR"/}"
  local label="$rel"
  [[ "$strategy" != "replace" ]] && label="$rel [$strategy]"

  if [[ ! -f "$src" ]]; then
    log_warn "skip ${rel} — template source not found (${src#"$BOOTSTRAP_ROOT"/})"
    printf 'skipped-nosrc\n'
    return 0
  fi

  # Absent destination: a plain write covers both replace and merge strategies
  # (merging into nothing yields the template itself).
  if [[ ! -e "$dest" ]]; then
    if is_dry_run; then
      log_dry "create ${label}"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      log_ok "create ${label}"
    fi
    printf 'created\n'
    return 0
  fi

  # Present and byte-identical: nothing to do.
  if cmp -s "$src" "$dest"; then
    log_info "ok ${rel} — already up to date"
    printf 'identical\n'
    return 0
  fi

  # Present and different.
  if [[ "$strategy" != "replace" ]]; then
    log_info "merge ${rel} — differs, merge pending (step 6)"
    printf 'merge-pending\n'
    return 0
  fi

  if [[ "$NO_OVERWRITE" == "1" ]]; then
    log_warn "skip ${rel} — differs but --no-overwrite is set"
    printf 'skipped-nooverwrite\n'
    return 0
  fi

  local bpath="$BACKUP_RUN_DIR/$rel"
  if is_dry_run; then
    log_dry "replace ${rel} — would back up to $(tildify "$bpath") then overwrite"
    printf 'replaced\n'
    return 0
  fi

  backup_file "$dest" >/dev/null
  cp "$src" "$dest"
  log_ok "replace ${rel} — backed up to $(tildify "$bpath")"
  printf 'replaced\n'
}

# run_apply <profile> <target-dir>
# Iterates the profile's resolved file list, deposits each one and prints a
# summary. Sets TARGET_DIR (for relative paths) and BACKUP_RUN_DIR (this run's
# backup folder).
run_apply() {
  local profile="$1"
  TARGET_DIR="$2"
  BACKUP_RUN_DIR="$BACKUP_BASE/$(basename "$TARGET_DIR")/$(date +%Y%m%dT%H%M%S)"

  local src dest strat srcpath destpath status
  local n_created=0 n_identical=0 n_replaced=0 n_noover=0 n_merge=0 n_nosrc=0

  while IFS=$'\t' read -r src dest strat; do
    [[ -z "$dest" ]] && continue
    srcpath="$BOOTSTRAP_ROOT/$src"
    destpath="$TARGET_DIR/$dest"
    status="$(deposit_file "$srcpath" "$destpath" "$strat")"
    case "$status" in
      created)             n_created=$((n_created + 1)) ;;
      identical)           n_identical=$((n_identical + 1)) ;;
      replaced)            n_replaced=$((n_replaced + 1)) ;;
      skipped-nooverwrite) n_noover=$((n_noover + 1)) ;;
      merge-pending)       n_merge=$((n_merge + 1)) ;;
      skipped-nosrc)       n_nosrc=$((n_nosrc + 1)) ;;
    esac
  done < <(resolve_files "$profile")

  printf '\n' >&2
  local verb="Applied"; is_dry_run && verb="Dry-run"
  log_info "${verb}: ${n_created} created, ${n_identical} unchanged, ${n_replaced} replaced (backed up), ${n_merge} merge-pending, ${n_noover} skipped (--no-overwrite), ${n_nosrc} not-yet-authored."
}
