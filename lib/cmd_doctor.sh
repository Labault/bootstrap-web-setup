# shellcheck shell=bash
# `bootstrap doctor` — check that the binaries required by the profile are present
# (blocking step before any deposit). Reports each binary OK/missing and suggests
# an install command for the missing ones.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"
# shellcheck source=lib/bincheck.sh
source "$BOOTSTRAP_ROOT/lib/bincheck.sh"

cmd_doctor() {
  local target="." override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat >&2 <<EOF
Usage: bootstrap doctor [--target <dir>] [--profile <name>]

Check that every binary required by the (detected or given) profile is installed.
Exit code 0 if all present, 1 if at least one is missing.
EOF
        return 0 ;;
      --target) target="${2:?--target needs a value}"; shift ;;
      --target=*) target="${1#*=}" ;;
      --profile) override="${2:?--profile needs a value}"; shift ;;
      --profile=*) override="${1#*=}" ;;
      *) die "Unknown option for 'doctor': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"

  local profile; profile="$(resolve_profile "$target" "$override")"
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
    return 0
  fi

  log_error "${missing}/${total} required binaries are missing (see install commands above)."
  return 1
}
