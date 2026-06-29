# shellcheck shell=bash
# `bootstrap update` — update bootstrap itself, façon `mac update`. It pulls the
# repo bootstrap is installed from. It NEVER touches projects (§9.1).

cmd_update() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      cat >&2 <<EOF
Usage: bootstrap update [--dry-run]

Update bootstrap itself (git pull in its own checkout). Never touches projects.
With --dry-run, fetch and report whether an update is available without pulling.
EOF
      return 0
      ;;
    *) die "Unknown option for 'update': $1" ;;
    esac
    shift
  done

  if ! git -C "$BOOTSTRAP_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "bootstrap is not a git checkout ($BOOTSTRAP_ROOT) — cannot self-update."
  fi

  local before
  before="$(bootstrap_version)"

  if is_dry_run; then
    log_info "fetching to preview updates…"
    git -C "$BOOTSTRAP_ROOT" fetch --quiet || die "git fetch failed"
    local behind=0
    behind="$(git -C "$BOOTSTRAP_ROOT" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)"
    if [[ "$behind" -gt 0 ]]; then
      log_dry "would update bootstrap: ${behind} commit(s) behind upstream (git pull --ff-only)"
    else
      log_ok "bootstrap is up to date (version ${before})."
    fi
    return 0
  fi

  log_info "updating bootstrap (git pull --ff-only)…"
  if git -C "$BOOTSTRAP_ROOT" pull --ff-only --quiet; then
    local after
    after="$(bootstrap_version)"
    if [[ "$before" == "$after" ]]; then
      log_ok "bootstrap is up to date (version ${after}). Projects are untouched."
    else
      log_ok "bootstrap updated: ${before} -> ${after}. Projects are untouched."
    fi
  else
    die "git pull failed (local changes or diverged history?). Resolve manually in ${BOOTSTRAP_ROOT}."
  fi
}
