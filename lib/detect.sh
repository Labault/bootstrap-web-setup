# shellcheck shell=bash
# Profile auto-detection and resolution.
#
# Detection rules (§11.7):
#   composer.json present            -> symfony
#   composer.json + package.json     -> fullstack
#   otherwise                        -> minimal
# A package.json without composer.json stays `minimal`: fullstack extends symfony,
# which presupposes PHP, so a front-only repo gets the language-agnostic base.

# detect_profile <target-dir> -> prints the auto-detected profile name
detect_profile() {
  local target="${1:-.}"
  if [[ -f "$target/composer.json" ]]; then
    if [[ -f "$target/package.json" ]]; then
      printf 'fullstack\n'
    else
      printf 'symfony\n'
    fi
  else
    printf 'minimal\n'
  fi
}

# profile_exists <name> -> 0 if a manifest exists for this profile
profile_exists() {
  [[ -f "$(manifest_path "$1")" ]]
}

# resolve_profile <target-dir> <override>
#   <override> empty  -> auto-detect from target
#   <override> set    -> validate and use it
# Prints the resolved profile name. Dies on an unknown override.
resolve_profile() {
  local target="${1:-.}" override="${2:-}"
  local profile
  if [[ -n "$override" ]]; then
    profile_exists "$override" || die "Unknown profile: '$override' (available: $(available_profiles | paste -sd ',' - | sed 's/,/, /g'))"
    profile="$override"
  else
    profile="$(detect_profile "$target")"
  fi
  # Validate the whole inheritance chain here (top level), so an unknown parent or
  # a cycle dies instead of being swallowed later inside a process substitution.
  resolve_chain "$profile" >/dev/null
  printf '%s\n' "$profile"
}

# available_profiles -> one profile name per line (from profiles/*.yaml)
available_profiles() {
  local f
  for f in "$BOOTSTRAP_ROOT"/profiles/*.yaml; do
    [[ -e "$f" ]] || continue
    basename "$f" .yaml
  done
}
