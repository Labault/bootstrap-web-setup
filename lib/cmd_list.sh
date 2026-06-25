# shellcheck shell=bash
# `bootstrap list` — list available profiles and their resolved content.

# shellcheck source=lib/manifest.sh
source "$BOOTSTRAP_ROOT/lib/manifest.sh"

cmd_list() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat >&2 <<EOF
Usage: bootstrap list

List the available profiles, their inheritance, required binaries and the files
they deposit (inheritance resolved).
EOF
        return 0 ;;
      *) die "Unknown option for 'list': $1" ;;
    esac
  done

  local manifest profile parent count
  local found=0
  for manifest in "$BOOTSTRAP_ROOT"/profiles/*.yaml; do
    [[ -e "$manifest" ]] || continue
    found=1
    profile="$(basename "$manifest" .yaml)"
    parent="$(manifest_extends "$manifest")"

    if [[ -n "$parent" ]]; then
      printf '%s%s%s  %s(extends %s)%s\n' \
        "$C_BOLD" "$profile" "$C_RESET" "$C_DIM" "$parent" "$C_RESET"
    else
      printf '%s%s%s\n' "$C_BOLD" "$profile" "$C_RESET"
    fi

    printf '  %srequires_bin:%s ' "$C_DIM" "$C_RESET"
    resolve_requires_bin "$profile" | paste -sd ' ' -

    count="$(resolve_files "$profile" | wc -l | tr -d '[:space:]')"
    printf '  %sfiles (%s):%s\n' "$C_DIM" "$count" "$C_RESET"
    resolve_files "$profile" | while IFS=$'\t' read -r _src dest strat; do
      if [[ "$strat" != "replace" ]]; then
        printf '    %s  %s[%s]%s\n' "$dest" "$C_DIM" "$strat" "$C_RESET"
      else
        printf '    %s\n' "$dest"
      fi
    done
    printf '\n'
  done

  [[ "$found" == 1 ]] || die "No profiles found in $BOOTSTRAP_ROOT/profiles/"
}
