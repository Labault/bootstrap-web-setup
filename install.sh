#!/usr/bin/env bash
#
# install.sh — make the `bootstrap` CLI callable, façon mac-setup.
# It symlinks bin/bootstrap into a directory on your PATH. It installs no other
# binaries. Re-runnable (idempotent). Honors --dry-run.
#
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  printf 'install: bash 4+ required (found %s). brew install bash\n' "${BASH_VERSION}" >&2
  exit 1
fi

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      cat >&2 <<EOF
Usage: ./install.sh [--dry-run]

Symlink the bootstrap CLI into a directory on your PATH.

Environment:
  BOOTSTRAP_BIN_DIR   Target dir for the symlink (default: ~/.local/bin)
EOF
      exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

BIN_DIR="${BOOTSTRAP_BIN_DIR:-$HOME/.local/bin}"
SRC="$SCRIPT_DIR/bin/bootstrap"
LINK="$BIN_DIR/bootstrap"

[[ -f "$SRC" ]] || die "Cannot find the CLI at $SRC"

# Already correctly linked? Nothing to do.
if [[ -L "$LINK" && "$(readlink "$LINK")" == "$SRC" ]]; then
  log_ok "bootstrap already installed: $(tildify "$LINK") -> $(tildify "$SRC")"
else
  if is_dry_run; then
    [[ -d "$BIN_DIR" ]] || log_dry "would create $(tildify "$BIN_DIR")"
    if [[ -e "$LINK" || -L "$LINK" ]]; then
      log_dry "would back up existing $(tildify "$LINK") then replace it"
    fi
    log_dry "would symlink $(tildify "$LINK") -> $(tildify "$SRC")"
  else
    mkdir -p "$BIN_DIR"
    chmod +x "$SRC"
    # Back up anything already at the target that isn't our symlink.
    if [[ -e "$LINK" || -L "$LINK" ]]; then
      backup="${LINK}.bak.$(date +%Y%m%dT%H%M%S)"
      mv "$LINK" "$backup"
      log_warn "backed up existing $(tildify "$LINK") -> $(tildify "$backup")"
    fi
    ln -s "$SRC" "$LINK"
    log_ok "installed bootstrap: $(tildify "$LINK") -> $(tildify "$SRC")"
  fi
fi

# PATH check.
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *)
    log_warn "$(tildify "$BIN_DIR") is not on your PATH. Add it, e.g.:"
    # The literal $PATH below is intentional — it's a snippet the user pastes.
    # shellcheck disable=SC2016
    printf '    echo '\''export PATH="%s:$PATH"'\'' >> ~/.zshrc\n' "$BIN_DIR" >&2
    ;;
esac

if ! is_dry_run; then
  log_info "Try it: bootstrap --version && bootstrap list"
fi
