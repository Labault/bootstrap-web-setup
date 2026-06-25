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
# Depends on lib/common.sh (logging, is_dry_run) and lib/merge.sh (renderers).

# shellcheck source=lib/merge.sh
source "$BOOTSTRAP_ROOT/lib/merge.sh"
# shellcheck source=lib/state.sh
source "$BOOTSTRAP_ROOT/lib/state.sh"

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

  # Merge strategies have their own renderer-driven path (idempotent, additive).
  case "$strategy" in
    merge-gitignore) deposit_merge "$src" "$dest" "$strategy" render_gitignore '' ; return 0 ;;
    merge-json)      deposit_merge "$src" "$dest" "$strategy" render_extensions_json canonical_json ; return 0 ;;
  esac

  # --- replace strategy --------------------------------------------------------
  # Absent destination: a plain write.
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

# deposit_merge <src> <dest> <strategy> <render_fn> <canon_fn>
# Drives a merge-strategy file. <render_fn> prints the full desired content;
# <canon_fn> (may be empty) canonicalizes a file for change detection (used for
# JSON, where formatting differences must not count as a change).
# Status tokens: created | identical | merged | skipped-nooverwrite.
deposit_merge() {
  local src="$1" dest="$2" strategy="$3" render_fn="$4" canon_fn="$5"
  local rel="${dest#"$TARGET_DIR"/}"
  local label="$rel [$strategy]"
  local bpath="$BACKUP_RUN_DIR/$rel"

  local new; new="$("$render_fn" "$dest" "$src")"

  # Fresh file: just write the rendered content (no backup needed).
  if [[ ! -e "$dest" ]]; then
    if is_dry_run; then
      log_dry "create ${label}"
    else
      mkdir -p "$(dirname "$dest")"
      printf '%s\n' "$new" > "$dest"
      log_ok "create ${label}"
    fi
    printf 'created\n'
    return 0
  fi

  # Existing file: has the merged result actually changed anything?
  local same=0
  if [[ -n "$canon_fn" ]]; then
    local tmp; tmp="$(mktemp)"; printf '%s\n' "$new" > "$tmp"
    [[ "$("$canon_fn" "$dest")" == "$("$canon_fn" "$tmp")" ]] && same=1
    rm -f "$tmp"
  else
    [[ "$(cat "$dest")" == "$new" ]] && same=1
  fi
  if [[ "$same" == 1 ]]; then
    log_info "ok ${rel} — already up to date [${strategy}]"
    printf 'identical\n'
    return 0
  fi

  if [[ "$NO_OVERWRITE" == "1" ]]; then
    log_warn "skip ${rel} — would merge but --no-overwrite is set"
    printf 'skipped-nooverwrite\n'
    return 0
  fi

  if is_dry_run; then
    log_dry "merge ${label} — would back up to $(tildify "$bpath") then update"
    printf 'merged\n'
    return 0
  fi

  backup_file "$dest" >/dev/null
  printf '%s\n' "$new" > "$dest"
  log_ok "merge ${label} — backed up to $(tildify "$bpath")"
  printf 'merged\n'
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
  local n_created=0 n_identical=0 n_replaced=0 n_merged=0 n_noover=0 n_nosrc=0
  # Files bootstrap now manages in the project (for .bootstrap.yaml).
  MANAGED_FILES=()

  while IFS=$'\t' read -r src dest strat; do
    [[ -z "$dest" ]] && continue
    srcpath="$BOOTSTRAP_ROOT/$src"
    destpath="$TARGET_DIR/$dest"
    status="$(deposit_file "$srcpath" "$destpath" "$strat")"
    case "$status" in
      created)             n_created=$((n_created + 1)) ;;
      identical)           n_identical=$((n_identical + 1)) ;;
      replaced)            n_replaced=$((n_replaced + 1)) ;;
      merged)              n_merged=$((n_merged + 1)) ;;
      skipped-nooverwrite) n_noover=$((n_noover + 1)) ;;
      skipped-nosrc)       n_nosrc=$((n_nosrc + 1)) ;;
    esac
    # A file is "managed" once it exists and came from us: created, replaced,
    # merged or already-identical. Skipped (no source / --no-overwrite) are not.
    case "$status" in
      created|identical|replaced|merged) MANAGED_FILES+=("${dest}"$'\t'"${strat}") ;;
    esac
  done < <(resolve_files "$profile")

  printf '\n' >&2
  local verb="Applied"; is_dry_run && verb="Dry-run"
  log_info "${verb}: ${n_created} created, ${n_identical} unchanged, ${n_replaced} replaced, ${n_merged} merged, ${n_noover} skipped (--no-overwrite), ${n_nosrc} not-yet-authored."

  # State file: written on a real apply only; previewed in dry-run.
  if is_dry_run; then
    log_dry "would write ${STATE_FILE_NAME} (profile, version, ${#MANAGED_FILES[@]} files + hashes)"
  else
    write_bootstrap_state "$TARGET_DIR" "$profile"
    log_ok "wrote ${STATE_FILE_NAME} (${#MANAGED_FILES[@]} files tracked)"
  fi
}

# install_hooks <target>
# Activates pre-commit hooks (§9.7) after deposit. Skipped (with a reason) when
# the target is not a git repo, pre-commit is absent, or no config was deposited.
# bootstrap installs hooks but never installs the pre-commit binary itself.
install_hooks() {
  local target="$1"
  local cfg="$target/.pre-commit-config.yaml"

  if [[ ! -f "$cfg" ]]; then
    log_info "hooks: skipped — no .pre-commit-config.yaml deposited yet"
    return 0
  fi
  if ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_warn "hooks: skipped — ${target} is not a git repository (run 'git init' then re-apply)"
    return 0
  fi
  if ! has_bin pre-commit; then
    log_warn "hooks: skipped — pre-commit not installed (brew install pre-commit)"
    return 0
  fi

  if is_dry_run; then
    log_dry "would run: pre-commit install && pre-commit install --hook-type commit-msg"
    return 0
  fi

  if ( cd "$target" && pre-commit install >/dev/null && pre-commit install --hook-type commit-msg >/dev/null ); then
    log_ok "hooks: pre-commit installed (pre-commit + commit-msg)"
  else
    log_warn "hooks: pre-commit install failed — run it manually in ${target}"
  fi
}

# package_in_json <json-file> <package> -> 0 if the package name appears in the file
package_in_json() {
  [[ -f "$1" ]] && grep -qF "\"$2\"" "$1"
}

# print_suggestions <target> <profile>
# Prints the composer/npm dev packages the profile recommends but that are not
# already declared. bootstrap never edits the manifests (§5.3/§10) — it only
# prints the command to run.
print_suggestions() {
  local target="$1" profile="$2"
  local pkg
  local -a composer_missing=() npm_missing=()

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    package_in_json "$target/composer.json" "$pkg" || composer_missing+=("$pkg")
  done < <(resolve_seq "$profile" suggest_composer)

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    package_in_json "$target/package.json" "$pkg" || npm_missing+=("$pkg")
  done < <(resolve_seq "$profile" suggest_npm)

  if [[ ${#composer_missing[@]} -gt 0 ]]; then
    log_info "Suggested PHP dev deps (bootstrap won't touch composer.json):"
    printf '    composer require --dev %s\n' "${composer_missing[*]}" >&2
  fi
  if [[ ${#npm_missing[@]} -gt 0 ]]; then
    log_info "Suggested JS dev deps (bootstrap won't touch package.json):"
    printf '    npm install -D %s\n' "${npm_missing[*]}" >&2
  fi
}
