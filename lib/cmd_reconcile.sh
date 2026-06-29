# shellcheck shell=bash
# `bootstrap reconcile` — bring a project up to date with the current templates
# via a 3-way merge (Phase 3), keeping local edits. Backs up before writing;
# conflicts are written with markers for manual resolution. Never auto-resolves.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"
# shellcheck source=lib/detect.sh
source "$BOOTSTRAP_ROOT/lib/detect.sh"
# shellcheck source=lib/merge.sh
source "$BOOTSTRAP_ROOT/lib/merge.sh"
# shellcheck source=lib/apply.sh
source "$BOOTSTRAP_ROOT/lib/apply.sh"
# shellcheck source=lib/state_read.sh
source "$BOOTSTRAP_ROOT/lib/state_read.sh"
# shellcheck source=lib/reconcile.sh
source "$BOOTSTRAP_ROOT/lib/reconcile.sh"

cmd_reconcile() {
  local target="."
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      cat >&2 <<EOF
Usage: bootstrap reconcile [--target <dir>] [--dry-run]

3-way merge the project's files with the current templates, keeping local edits.
The merge base is the template at the commit recorded in .bootstrap.yaml. Files
are backed up first; conflicts are written with markers to resolve by hand.
Requires the project to have been set up by bootstrap (.bootstrap.yaml present).

  --dry-run   Show what would merge / conflict without writing.
EOF
      return 0
      ;;
    --target)
      target="${2:?--target needs a value}"
      shift
      ;;
    --target=*) target="${1#*=}" ;;
    *) die "Unknown option for 'reconcile': $1" ;;
    esac
    shift
  done

  [[ -d "$target" ]] || die "Target is not a directory: $target"
  target="$(cd "$target" && pwd)"

  # bootstrap's own runtime deps, checked up front (die exits properly here):
  # git for the 3-way merge (git merge-file / git show), jq for merge rendering.
  require_cmd git
  require_cmd jq
  warn_if_bootstrap_dirty

  local state="$target/$STATE_FILE_NAME"
  [[ -f "$state" ]] || die "No ${STATE_FILE_NAME} in ${target} — nothing to reconcile (run 'bootstrap apply' first)."

  local profile commit
  profile="$(state_profile "$state")"
  commit="$(state_commit "$state")"
  [[ -n "$profile" ]] || die "Could not read profile from ${state}."

  if is_dry_run; then
    log_info "reconcile (dry-run) profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  else
    log_info "reconcile profile ${C_BOLD}${profile}${C_RESET} -> ${target}"
  fi
  if [[ -z "$commit" || "$commit" == "unknown" ]]; then
    log_warn "no merge base recorded (bootstrap_commit) — files will be backed up + replaced instead of merged."
  fi

  reconcile_run "$target" "$profile" "$commit"
}
