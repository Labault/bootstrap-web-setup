# shellcheck shell=bash
# Drift detection (Phase 2). Compares a project's .bootstrap.yaml against the
# current templates and reports, per file, whether it is in sync, behind the
# template, locally modified, missing, new or orphaned. It SIGNALS only — it
# never merges (Phase 3). Depends on: common.sh, manifest.sh, merge.sh, state_read.sh.

# expected_hash <src> <dest> <strategy> -> sha256 of what `apply` would produce now.
# replace: the template is copied verbatim, so it's the template's own hash.
# merge: render against the current on-disk file (matches apply's write), then hash.
expected_hash() {
  local src="$1" dest="$2" strategy="$3"
  case "$strategy" in
    merge-gitignore) printf '%s\n' "$(render_gitignore "$dest" "$src")" | sha256_stdin ;;
    merge-json)      printf '%s\n' "$(render_extensions_json "$dest" "$src")" | sha256_stdin ;;
    *)               file_sha256 "$src" ;;
  esac
}

# detect_drift <target> <profile>
# Prints a per-file drift report and a summary. Returns 0 when everything is in
# sync, 1 when any drift is found (the caller decides whether that's fatal).
detect_drift() {
  local target="$1" profile="$2"
  local state="$target/$STATE_FILE_NAME"

  # Current profile's files: dest -> src / strategy, plus a stable order.
  local -A cur_src=() cur_strat=()
  local -a cur_order=()
  local src dest strat
  while IFS=$'\t' read -r src dest strat; do
    [[ -z "$dest" ]] && continue
    cur_src["$dest"]="$src"
    cur_strat["$dest"]="$strat"
    cur_order+=("$dest")
  done < <(resolve_files "$profile")

  local -A tracked=()
  local n_ok=0 n_out=0 n_mod=0 n_miss=0 n_new=0 n_orphan=0

  # 1) Walk the tracked files recorded in .bootstrap.yaml.
  local path rec_hash tpl_rec csrc cstrat dpath D P Tcur
  while IFS=$'\t' read -r path rec_hash tpl_rec _; do
    [[ -z "$path" ]] && continue
    tracked["$path"]=1
    dpath="$target/$path"

    if [[ -z "${cur_src[$path]+x}" ]]; then
      printf '  %s⊘%s %s %s(orphaned — no longer in profile)%s\n' "$C_DIM" "$C_RESET" "$path" "$C_DIM" "$C_RESET" >&2
      n_orphan=$((n_orphan + 1)); continue
    fi
    if [[ ! -e "$dpath" ]]; then
      printf '  %s✗%s %s %s(missing — re-apply would recreate)%s\n' "$C_RED" "$C_RESET" "$path" "$C_DIM" "$C_RESET" >&2
      n_miss=$((n_miss + 1)); continue
    fi

    csrc="$BOOTSTRAP_ROOT/${cur_src[$path]}"; cstrat="${cur_strat[$path]}"
    D="$(file_sha256 "$dpath")"
    P=""; [[ -f "$csrc" ]] && P="$(expected_hash "$csrc" "$dpath" "$cstrat")"

    if [[ -n "$P" && "$D" == "$P" ]]; then
      printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$path" >&2
      n_ok=$((n_ok + 1))
    elif [[ "$D" != "$rec_hash" ]]; then
      printf '  %s!%s %s %s(modified locally — reconcile to merge, or re-apply to overwrite)%s\n' "$C_YELLOW" "$C_RESET" "$path" "$C_DIM" "$C_RESET" >&2
      n_mod=$((n_mod + 1))
    else
      # File untouched since the last apply/reconcile (D == recorded). Did the
      # TEMPLATE move, or are these recorded local edits that are still current?
      Tcur=""; [[ -f "$csrc" ]] && Tcur="$(file_sha256 "$csrc")"
      if [[ -n "$tpl_rec" && -n "$Tcur" && "$tpl_rec" == "$Tcur" ]]; then
        printf '  %s✓%s %s %s(local edits kept; up to date)%s\n' "$C_GREEN" "$C_RESET" "$path" "$C_DIM" "$C_RESET" >&2
        n_ok=$((n_ok + 1))
      else
        printf '  %s~%s %s %s(template updated — reconcile/re-apply to update)%s\n' "$C_YELLOW" "$C_RESET" "$path" "$C_DIM" "$C_RESET" >&2
        n_out=$((n_out + 1))
      fi
    fi
  done < <(state_files "$state")

  # 2) Files the current profile adds that the project never received (stable order).
  for dest in "${cur_order[@]}"; do
    [[ -n "${tracked[$dest]+x}" ]] && continue
    printf '  %s+%s %s %s(new — re-apply would add)%s\n' "$C_BLUE" "$C_RESET" "$dest" "$C_DIM" "$C_RESET" >&2
    n_new=$((n_new + 1))
  done

  local drift=$((n_out + n_mod + n_miss + n_new))
  printf '\n' >&2
  if [[ "$drift" -eq 0 && "$n_orphan" -eq 0 ]]; then
    log_ok "No drift: ${n_ok} file(s) in sync with the current templates."
    return 0
  fi
  log_warn "Drift: ${n_out} behind, ${n_mod} modified locally, ${n_miss} missing, ${n_new} new, ${n_orphan} orphaned (${n_ok} in sync)."
  log_info "To update while keeping local edits (3-way merge, backs up first):"
  printf '    bootstrap reconcile\n' >&2
  log_info "Or to overwrite with the templates (backs up first):"
  printf '    bootstrap apply --profile %s\n' "$profile" >&2
  return 1
}
