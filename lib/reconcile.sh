# shellcheck shell=bash
# Reconciliation (Phase 3): a real 3-way merge that brings a project up to date
# with the current templates while keeping local edits. The merge base (O) is the
# template at the commit recorded in .bootstrap.yaml, retrieved via `git show`
# (cruft-style). Uses git merge-file; conflicts are written with markers for the
# user to resolve. Depends on: common.sh, manifest.sh, merge.sh, apply.sh
# (backup_file, deposit_merge, deposit_file), state_read.sh.

# three_way_merge <path> <src> <commit>
# A = local (on disk), O = base (template@commit), B = new template.
# Sets DEPOSIT_RESULT: updated | merged | conflict | insync | replaced-nobase.
three_way_merge() {
  local path="$1" src="$2" commit="$3"
  local dpath="$TARGET_DIR/$path" srcpath="$BOOTSTRAP_ROOT/$src"

  if [[ -z "$commit" || "$commit" == "unknown" ]]; then
    _reconcile_no_base "$path" "$srcpath"
    return
  fi

  local tmpO; tmpO="$(mktemp)"
  if ! git -C "$BOOTSTRAP_ROOT" show "${commit}:${src}" > "$tmpO" 2>/dev/null; then
    rm -f "$tmpO"
    _reconcile_no_base "$path" "$srcpath"
    return
  fi

  # Fast-forward: the local file is unchanged from the base (no local edits), so
  # just take the new template — no merge needed, nothing to lose.
  if [[ "$(file_sha256 "$dpath")" == "$(file_sha256 "$tmpO")" ]]; then
    rm -f "$tmpO"
    if is_dry_run; then
      log_dry "update ${path} (template changed; no local edits)"
    else
      backup_file "$dpath"
      cp "$srcpath" "$dpath" || die "cannot write ${path}"
      log_ok "update ${path} (fast-forward, backed up)"
    fi
    DEPOSIT_RESULT='updated'; return
  fi

  local tmpM; tmpM="$(mktemp)"
  local rc=0
  git merge-file -p \
    -L "your version (${path})" -L "base" -L "bootstrap template" \
    "$dpath" "$tmpO" "$srcpath" > "$tmpM" 2>/dev/null || rc=$?
  rm -f "$tmpO"

  # No-op: the merge reproduces the current file (e.g. re-running after a clean
  # reconcile). Don't back up or rewrite — report it as in sync.
  if [[ "$rc" -eq 0 && "$(file_sha256 "$tmpM")" == "$(file_sha256 "$dpath")" ]]; then
    rm -f "$tmpM"
    DEPOSIT_RESULT='insync'; return
  fi

  if is_dry_run; then
    rm -f "$tmpM"
    if [[ "$rc" -eq 0 ]]; then
      log_dry "merge ${path} — would merge cleanly (local edits + template update)"
      DEPOSIT_RESULT='merged'
    else
      log_dry "merge ${path} — would merge WITH CONFLICTS (${rc}) to resolve by hand"
      DEPOSIT_RESULT='conflict'
    fi
    return
  fi

  backup_file "$dpath"
  mv "$tmpM" "$dpath" || die "cannot write merged ${path}"
  if [[ "$rc" -eq 0 ]]; then
    log_ok "merge ${path} — merged cleanly (backed up first)"
    DEPOSIT_RESULT='merged'
  else
    log_warn "merge ${path} — ${rc} conflict(s) written with markers; resolve by hand (backed up first)"
    DEPOSIT_RESULT='conflict'
  fi
}

# _reconcile_no_base <path> <srcpath>: no base available -> Phase-1 behavior.
_reconcile_no_base() {
  local path="$1" srcpath="$2"
  local dpath="$TARGET_DIR/$path"
  if is_dry_run; then
    log_dry "replace ${path} — no merge base available; would back up + replace"
    DEPOSIT_RESULT='replaced-nobase'; return
  fi
  backup_file "$dpath"
  cp "$srcpath" "$dpath" || die "cannot write ${path}"
  log_warn "replace ${path} — no merge base (commit unknown); backed up + replaced"
  DEPOSIT_RESULT='replaced-nobase'
}

# reconcile_file <path> <src> <strategy> <commit>
# Sets DEPOSIT_RESULT (see deposit_merge / three_way_merge, plus
# skip-nosrc | recreated | insync). Called directly (not in $()).
reconcile_file() {
  local path="$1" src="$2" strategy="$3" commit="$4"
  local dpath="$TARGET_DIR/$path" srcpath="$BOOTSTRAP_ROOT/$src"

  # Merge-strategy files already have a non-destructive additive merge — reuse it.
  case "$strategy" in
    merge-gitignore) deposit_merge "$srcpath" "$dpath" "$strategy" render_gitignore '' ; return ;;
    merge-json)      deposit_merge "$srcpath" "$dpath" "$strategy" render_extensions_json canonical_json ; return ;;
  esac

  if [[ ! -f "$srcpath" ]]; then DEPOSIT_RESULT='skip-nosrc'; return; fi

  if [[ -d "$dpath" ]]; then die "cannot reconcile ${path}: a directory exists there."; fi

  if [[ ! -e "$dpath" ]]; then
    if is_dry_run; then log_dry "recreate ${path} (missing)"; else
      mkdir -p "$(dirname "$dpath")" || die "cannot create parent dir for ${path}"
      cp "$srcpath" "$dpath" || die "cannot write ${path}"
      log_ok "recreate ${path}"
    fi
    DEPOSIT_RESULT='recreated'; return
  fi

  # Already identical to the current template -> nothing to do.
  if [[ "$(file_sha256 "$dpath")" == "$(file_sha256 "$srcpath")" ]]; then
    DEPOSIT_RESULT='insync'; return
  fi

  # Otherwise 3-way merge. It fast-forwards when the file equals the base (no
  # local edits) and preserves baked-in edits when the template moved.
  three_way_merge "$path" "$src" "$commit"
}

# reconcile_run <target> <profile> <commit>
reconcile_run() {
  local target="$1" profile="$2" commit="$3"
  # TARGET_DIR / BACKUP_RUN_DIR are consumed by backup_file (lib/apply.sh).
  # shellcheck disable=SC2034
  TARGET_DIR="$target"
  # shellcheck disable=SC2034
  BACKUP_RUN_DIR="$BACKUP_BASE/$(basename "$target")/$(date +%Y%m%dT%H%M%S)-$$"
  local state="$target/$STATE_FILE_NAME"

  local -A cur_src=() cur_strat=() tracked=()
  local -a cur_order=()   # deterministic resolve_files order, for stable state output
  local src dest strat
  while IFS=$'\t' read -r src dest strat; do
    [[ -z "$dest" ]] && continue
    cur_src["$dest"]="$src"; cur_strat["$dest"]="$strat"; cur_order+=("$dest")
  done < <(resolve_files "$profile")

  local n_insync=0 n_updated=0 n_merged=0 n_conflict=0 n_recreated=0 n_nobase=0 n_new=0 n_orphan=0
  local path status
  while IFS=$'\t' read -r path _; do
    [[ -z "$path" ]] && continue
    tracked["$path"]=1
    if [[ -z "${cur_src[$path]+x}" ]]; then
      log_info "orphaned ${path} — no longer in profile, left as-is"
      n_orphan=$((n_orphan + 1)); continue
    fi
    DEPOSIT_RESULT=''
    reconcile_file "$path" "${cur_src[$path]}" "${cur_strat[$path]}" "$commit"
    status="$DEPOSIT_RESULT"
    case "$status" in
      insync|identical) n_insync=$((n_insync + 1)) ;;
      updated) n_updated=$((n_updated + 1)) ;;
      merged|created) n_merged=$((n_merged + 1)) ;;
      conflict) n_conflict=$((n_conflict + 1)) ;;
      recreated) n_recreated=$((n_recreated + 1)) ;;
      replaced-nobase) n_nobase=$((n_nobase + 1)) ;;
    esac
  done < <(state_files "$state")

  # Files the current profile adds that the project never received -> deposit them.
  for dest in "${cur_order[@]}"; do
    [[ -n "${tracked[$dest]+x}" ]] && continue
    DEPOSIT_RESULT=''
    deposit_file "$BOOTSTRAP_ROOT/${cur_src[$dest]}" "$target/$dest" "${cur_strat[$dest]}"
    n_new=$((n_new + 1))
  done

  printf '\n' >&2
  local verb="Reconciled"; is_dry_run && verb="Dry-run"
  log_info "${verb}: ${n_merged} merged, ${n_updated} fast-forwarded, ${n_recreated} recreated, ${n_new} added, ${n_conflict} CONFLICTS, ${n_nobase} replaced (no base), ${n_insync} in sync, ${n_orphan} orphaned."

  # Refresh .bootstrap.yaml so the recorded hashes + commit match the reconciled
  # result — otherwise a later `doctor` keeps flagging merged files as drifted.
  # Skip while conflicts remain (the files still carry markers): the user resolves
  # them, then re-runs to record a clean state.
  if [[ "$n_conflict" -gt 0 ]]; then
    log_warn "Resolve the ${n_conflict} conflicted file(s) (search for <<<<<<<), then re-run reconcile to refresh ${STATE_FILE_NAME}."
    return 1
  fi

  # Managed set = current-profile files now present on disk (orphans dropped), in
  # the deterministic resolve_files order so the state matches apply's ordering.
  MANAGED_FILES=()
  for dest in "${cur_order[@]}"; do
    [[ -e "$target/$dest" ]] && MANAGED_FILES+=("${dest}"$'\t'"${cur_strat[$dest]}"$'\t'"${cur_src[$dest]}")
  done
  if is_dry_run; then
    log_dry "would refresh ${STATE_FILE_NAME} (${#MANAGED_FILES[@]} files, current version + commit)"
  else
    write_bootstrap_state "$target" "$profile"
    log_ok "refreshed ${STATE_FILE_NAME} (${#MANAGED_FILES[@]} files tracked)"
  fi
  return 0
}
