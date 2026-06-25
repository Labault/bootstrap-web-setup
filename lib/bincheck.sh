# shellcheck shell=bash
# Required-binary checking, shared by `doctor` and (later) the blocking step-0
# guard in `apply`. Depends on lib/manifest.sh (resolve_requires_bin).

# install_hint <bin> -> a suggested install command for a missing binary.
# bootstrap never runs these; it only suggests them. Defaults to brew; binaries
# that don't ship a brew formula get their real package manager. Tune these to
# match mac-setup as it evolves.
install_hint() {
  case "$1" in
    markdownlint-cli2) printf 'npm install -g markdownlint-cli2\n' ;;
    commitlint)        printf 'npm install -g @commitlint/cli @commitlint/config-conventional\n' ;;
    eslint)            printf 'npm install -g eslint\n' ;;
    prettier)          printf 'npm install -g prettier\n' ;;
    phpstan)           printf 'composer global require phpstan/phpstan\n' ;;
    rector)            printf 'composer global require rector/rector\n' ;;
    *)                 printf 'brew install %s\n' "$1" ;;
  esac
}

# has_bin <bin> -> 0 if the binary is on PATH
has_bin() {
  command -v "$1" >/dev/null 2>&1
}

# missing_binaries <profile> -> prints, one per line, the required binaries that
# are NOT on PATH (in resolved order). Empty output means all present.
missing_binaries() {
  local bin
  while IFS= read -r bin; do
    [[ -z "$bin" ]] && continue
    has_bin "$bin" || printf '%s\n' "$bin"
  done < <(resolve_requires_bin "$1")
}
