# shellcheck shell=bash
# `bootstrap apply` — deposit the profile's config into the target project.
# Step 4 scope: absent files + --dry-run. Binary guard, collisions, .bootstrap.yaml
# and hook install come in later steps.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"
# shellcheck source=lib/apply.sh
source "$BOOTSTRAP_ROOT/lib/apply.sh"

cmd_apply() {
  local target="." override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat >&2 <<EOF
Usage: bootstrap apply [--target <dir>] [--profile <name>] [--dry-run]

Deposit the (detected or given) profile's config into <dir> (default: current
directory). Use --dry-run to preview without writing anything.
EOF
        return 0 ;;
      --target) target="${2:?--target needs a value}"; shift ;;
      --target=*) target="${1#*=}" ;;
      --profile) override="${2:?--profile needs a value}"; shift ;;
      --profile=*) override="${1#*=}" ;;
      *) die "Unknown option for 'apply': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"
  # Normalize to an absolute path so relative-path display and writes are stable.
  target="$(cd "$target" && pwd)"

  local profile; profile="$(resolve_profile "$target" "$override")"

  if is_dry_run; then
    log_info "apply (dry-run) profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  else
    log_info "apply profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  fi

  run_apply "$profile" "$target"
}
