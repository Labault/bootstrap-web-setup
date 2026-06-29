# shellcheck shell=bash
# Minimal colour helper for the greet CLI. Colours are disabled when stdout isn't
# a TTY, so piped or captured output (e.g. under bats) stays plain text.

if [[ -t 1 ]]; then
  _C_GREEN=$'\033[32m'
  _C_RESET=$'\033[0m'
else
  _C_GREEN=''
  _C_RESET=''
fi

# colorize <text> -> the text wrapped in green when colours are active.
colorize() {
  printf '%s%s%s' "$_C_GREEN" "$1" "$_C_RESET"
}
