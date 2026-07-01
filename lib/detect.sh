# shellcheck shell=bash
# Profile auto-detection and resolution.
#
# Detection rules (§11.7):
#   composer.json present            -> symfony
#   composer.json + package.json     -> fullstack
#   tracked *.sh/*.bash, no manifest -> shell
#   otherwise                        -> minimal
# A package.json without composer.json stays `minimal`: fullstack extends symfony,
# which presupposes PHP, so a front-only repo gets the language-agnostic base,
# and a front-only repo is never a `shell` tooling repo, hence the package.json
# guard on the shell branch.

# has_shell_signal <target-dir> -> 0 if the repo tracks shell sources.
# A tooling repo (bootstrap itself, server-setup…) carries shell scripts but no
# composer.json/package.json; tracked *.sh/*.bash files are the cue. We look at
# git-TRACKED files only: a stray script in an untracked scratch dir shouldn't
# flip the profile, and an empty repo stays minimal.
has_shell_signal() {
  local target="${1:-.}" tracked
  tracked="$(git -C "$target" ls-files -- '*.sh' '*.bash' 2>/dev/null)" || return 1
  [[ -n "$tracked" ]]
}

# detect_profile <target-dir> -> prints the auto-detected profile name
detect_profile() {
  local target="${1:-.}"
  if [[ -f "$target/composer.json" ]]; then
    if [[ -f "$target/package.json" ]]; then
      printf 'fullstack\n'
    else
      printf 'symfony\n'
    fi
  elif [[ ! -f "$target/package.json" ]] && has_shell_signal "$target"; then
    printf 'shell\n'
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
    # A profile name is a bare manifest stem: reject path separators so
    # --profile can't reach outside profiles/ (defence in depth).
    [[ "$override" == */* || "$override" == *..* ]] && die "Invalid profile name: '$override'"
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
