# shellcheck shell=bash
# `bootstrap apply` — deposit the profile's config into the target project.
# Resolves the profile, runs the blocking binary guard, deposits the files
# (collisions handled by the engine), writes .bootstrap.yaml, generates the
# PHPStan baseline, installs hooks, and prints dependency suggestions.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"
# shellcheck source=lib/bincheck.sh
source "$BOOTSTRAP_ROOT/lib/bincheck.sh"
# shellcheck source=lib/apply.sh
source "$BOOTSTRAP_ROOT/lib/apply.sh"

cmd_apply() {
  local target="." override="" skip_bin_check=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat >&2 <<EOF
Usage: bootstrap apply [--target <dir>] [--profile <name>] [--no-overwrite] [--skip-bin-check] [--dry-run]

Deposit the (detected or given) profile's config into <dir> (default: current directory).

  --target <dir>     Target project directory (default: current directory).
  --profile <name>   Force a profile instead of auto-detecting.
  --no-overwrite     Never overwrite an existing, differing file (skip it instead of replacing).
  --skip-bin-check   Don't block on missing required binaries (CI / deferred install).
  --dry-run          Preview without writing anything.
EOF
        return 0 ;;
      --target) target="${2:?--target needs a value}"; shift ;;
      --target=*) target="${1#*=}" ;;
      --profile) override="${2:?--profile needs a value}"; shift ;;
      --profile=*) override="${1#*=}" ;;
      --no-overwrite) NO_OVERWRITE=1 ;;
      --skip-bin-check) skip_bin_check=1 ;;
      *) die "Unknown option for 'apply': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"
  # Normalize to an absolute path so relative-path display and writes are stable.
  target="$(cd "$target" && pwd)"

  local profile; profile="$(resolve_profile "$target" "$override")"

  # bootstrap's own runtime dependency. Checked here at the top level (where die
  # actually exits) BEFORE writing anything, so a missing jq can never corrupt a
  # half-deposited project from inside a $() subshell during a merge.
  require_cmd jq
  warn_if_bootstrap_dirty

  if is_dry_run; then
    log_info "apply (dry-run) profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  else
    log_info "apply profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  fi

  # Blocking binary guard (§9.2): refuse to deposit dead config. --skip-bin-check
  # bypasses it (CI / deferred install).
  if [[ "$skip_bin_check" == 1 ]]; then
    log_warn "skipping required-binary check (--skip-bin-check)"
  else
    local -a missing=()
    local bin
    while IFS= read -r bin; do [[ -n "$bin" ]] && missing+=("$bin"); done \
      < <(missing_binaries "$profile")
    if [[ ${#missing[@]} -gt 0 ]]; then
      log_error "Missing ${#missing[@]} required binary/binaries for profile '${profile}':"
      for bin in "${missing[@]}"; do
        printf '    %s — %s\n' "$bin" "$(install_hint "$bin")" >&2
      done
      die "Install them (see above) or re-run with --skip-bin-check."
    fi
  fi

  run_apply "$profile" "$target"
  setup_phpstan_baseline "$target"
  install_hooks "$target"
  print_suggestions "$target" "$profile"
}
