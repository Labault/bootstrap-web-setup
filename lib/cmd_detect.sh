# shellcheck shell=bash
# `bootstrap detect` — auxiliary command: print the profile that would be used
# for a target directory. Handy for testing detection and for scripting.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"

cmd_detect() {
  local target="." override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat >&2 <<EOF
Usage: bootstrap detect [--target <dir>] [--profile <name>]

Print the profile that would be applied to <dir> (default: current directory).
With --profile, validate and echo that profile instead of auto-detecting.

Detection: composer.json -> symfony ; + package.json -> fullstack ; else minimal.
EOF
        return 0 ;;
      --target) target="${2:?--target needs a value}"; shift ;;
      --target=*) target="${1#*=}" ;;
      --profile) override="${2:?--profile needs a value}"; shift ;;
      --profile=*) override="${1#*=}" ;;
      *) die "Unknown option for 'detect': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"

  local profile; profile="$(resolve_profile "$target" "$override")"
  if [[ -n "$override" ]]; then
    log_info "Profile (overridden): ${C_BOLD}${profile}${C_RESET}"
  else
    log_info "Profile (auto-detected for ${target}): ${C_BOLD}${profile}${C_RESET}"
  fi
  printf '%s\n' "$profile"
}
