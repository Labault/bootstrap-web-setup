# shellcheck shell=bash
# `bootstrap doctor` — check the binaries required by the profile, and (Phase 2)
# detect configuration drift against the current templates when the project has a
# .bootstrap.yaml. Drift is reported, never merged.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"
# shellcheck source=lib/bincheck.sh
source "$BOOTSTRAP_ROOT/lib/bincheck.sh"
# shellcheck source=lib/merge.sh
source "$BOOTSTRAP_ROOT/lib/merge.sh"
# shellcheck source=lib/state_read.sh
source "$BOOTSTRAP_ROOT/lib/state_read.sh"
# shellcheck source=lib/drift.sh
source "$BOOTSTRAP_ROOT/lib/drift.sh"

cmd_doctor() {
  local target="." override="" strict=0 skip_bin_check=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      cat >&2 <<EOF
Usage: bootstrap doctor [--target <dir>] [--profile <name>] [--skip-bin-check] [--strict]

Check that every binary required by the (detected or given) profile is installed,
and report configuration drift against the current templates when the project has
a .bootstrap.yaml. Drift is informational by default.

  --skip-bin-check   Report missing binaries but don't exit non-zero for them.
  --strict           Exit non-zero if drift is detected (useful in CI).

Exit code: 1 if a required binary is missing (unless --skip-bin-check), or with
--strict if drift exists.
EOF
      return 0
      ;;
    --target)
      target="${2:?--target needs a value}"
      shift
      ;;
    --target=*) target="${1#*=}" ;;
    --profile)
      override="${2:?--profile needs a value}"
      shift
      ;;
    --profile=*) override="${1#*=}" ;;
    --skip-bin-check) skip_bin_check=1 ;;
    --strict) strict=1 ;;
    *) die "Unknown option for 'doctor': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"

  local profile
  profile="$(resolve_profile "$target" "$override")"
  log_info "Checking binaries for profile ${C_BOLD}${profile}${C_RESET}"

  local bin missing=0 total=0
  while IFS= read -r bin; do
    [[ -z "$bin" ]] && continue
    total=$((total + 1))
    if has_bin "$bin"; then
      printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$bin" >&2
    else
      missing=$((missing + 1))
      printf '  %s✗%s %s — %s%s%s\n' \
        "$C_RED" "$C_RESET" "$bin" "$C_DIM" "$(install_hint "$bin")" "$C_RESET" >&2
    fi
  done < <(resolve_requires_bin "$profile")

  if [[ "$missing" -eq 0 ]]; then
    log_ok "All ${total} required binaries are present."
  elif [[ "$skip_bin_check" -eq 1 ]]; then
    log_warn "${missing}/${total} required binaries are missing (not blocking: --skip-bin-check)."
  else
    log_error "${missing}/${total} required binaries are missing (see install commands above)."
  fi

  # --- Phase 2: drift detection (only if the project has a state file) ---------
  local drift_found=0
  local state="$target/$STATE_FILE_NAME"
  if [[ -f "$state" ]]; then
    # Drift comparison renders merge files, which needs jq. Fail clearly up front.
    require_cmd jq
    local rec_profile rec_version cur_version
    rec_profile="$(state_profile "$state")"
    rec_version="$(state_version "$state")"
    cur_version="$(bootstrap_version)"
    printf '\n' >&2
    # A state file with no readable profile is corrupt/hand-broken — say so plainly
    # rather than report every file as "new".
    if [[ -z "$rec_profile" ]] || ! profile_exists "$rec_profile"; then
      log_warn "Drift check: ${STATE_FILE_NAME} is unreadable or has an unknown profile — re-run 'bootstrap apply' to rewrite it."
      return 1
    fi
    log_info "Drift check (recorded profile ${C_BOLD}${rec_profile}${C_RESET}, applied $(state_applied_at "$state"))"
    if [[ "$rec_version" != "$cur_version" ]]; then
      log_warn "version: recorded ${rec_version} vs current ${cur_version} — templates may have changed"
    else
      printf '  %sversion: %s (up to date)%s\n' "$C_DIM" "$rec_version" "$C_RESET" >&2
    fi
    # Drift is compared against the profile that was actually applied.
    detect_drift "$target" "${rec_profile:-$profile}" || drift_found=1
  else
    printf '\n' >&2
    log_info "Drift check skipped — no ${STATE_FILE_NAME} (project not set up by bootstrap yet)."
  fi

  # --- Exit code ---------------------------------------------------------------
  [[ "$missing" -gt 0 && "$skip_bin_check" -ne 1 ]] && return 1
  [[ "$strict" -eq 1 && "$drift_found" -eq 1 ]] && return 1
  return 0
}
