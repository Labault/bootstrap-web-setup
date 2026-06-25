# shellcheck shell=bash
# Common library for bootstrap: logging, colors, dry-run handling, error helpers.
# Sourced by bin/bootstrap and command modules. Not meant to be executed directly.

# --- Colors (disabled if not a TTY or NO_COLOR is set) -----------------------
# These are part of the library's public API, consumed by scripts that source us.
# shellcheck disable=SC2034
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
else
  C_RESET='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_DIM='' C_BOLD=''
fi

# --- Logging (everything to stderr; stdout stays clean for data) -------------
log_info()  { printf '%s\n' "${C_BLUE}•${C_RESET} $*" >&2; }
log_ok()    { printf '%s\n' "${C_GREEN}✓${C_RESET} $*" >&2; }
log_warn()  { printf '%s\n' "${C_YELLOW}!${C_RESET} $*" >&2; }
log_error() { printf '%s\n' "${C_RED}✗${C_RESET} $*" >&2; }
log_dry()   { printf '%s\n' "${C_DIM}[dry-run]${C_RESET} $*" >&2; }

die() {
  log_error "$*"
  exit 1
}

# --- Global flags (populated by the dispatcher) ------------------------------
DRY_RUN="${DRY_RUN:-0}"

# True when running in dry-run mode.
is_dry_run() { [[ "$DRY_RUN" == "1" ]]; }

# --- Path helpers ------------------------------------------------------------
# tildify <path> -> path with a leading $HOME collapsed to ~ (display only).
# Done with string ops, not ${p/#$HOME/~}, because the replacement '~' would
# itself be tilde-expanded back to $HOME and the collapse would be a no-op.
tildify() {
  local p="$1"
  if [[ "$p" == "$HOME"/* ]]; then
    # Intentional literal '~' for display; we do NOT want it expanded.
    # shellcheck disable=SC2088
    printf '~/%s\n' "${p#"$HOME"/}"
  else
    printf '%s\n' "$p"
  fi
}

# --- Dependency guard --------------------------------------------------------
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# --- Misc helpers ------------------------------------------------------------
# bootstrap_version -> the template/CLI version from the repo's VERSION file.
bootstrap_version() {
  if [[ -f "$BOOTSTRAP_ROOT/VERSION" ]]; then
    tr -d '[:space:]' < "$BOOTSTRAP_ROOT/VERSION"
  else
    printf 'unknown'
  fi
}

# file_sha256 <file> -> hex sha256 of the file (portable: shasum or sha256sum).
file_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    printf 'sha256-unavailable'
  fi
}
