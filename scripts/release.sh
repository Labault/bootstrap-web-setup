#!/usr/bin/env bash

# Release helper for bootstrap-web-setup ITSELF (repo-only — not deposited to
# projects). Bumps VERSION, rolls CHANGELOG's [Unreleased] into a dated section,
# commits, tags vX.Y.Z, pushes, and creates the GitHub release from those notes.
#
# Usage:
#   scripts/release.sh <patch|minor|major>   # bump from the current VERSION
#   scripts/release.sh <X.Y.Z>               # set an explicit version
#   scripts/release.sh <bump> --dry-run      # show the plan, change nothing
#
# Workflow: describe changes under "## [Unreleased]" in CHANGELOG.md as you go,
# then run this when you want to cut a release.

set -euo pipefail

BASE_URL="https://github.com/Labault/bootstrap-web-setup"

die() { printf 'release: %s\n' "$*" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repository."

bump="${1:-}"
dry_run=0
[[ "${2:-}" == "--dry-run" ]] && dry_run=1
[[ -n "$bump" ]] || die "usage: release.sh <patch|minor|major|X.Y.Z> [--dry-run]"

[[ -f VERSION && -f CHANGELOG.md ]] || die "VERSION and CHANGELOG.md must exist."

cur="$(tr -d '[:space:]' < VERSION)"
IFS=. read -r major minor patch <<< "$cur"
case "$bump" in
  major) next="$((major + 1)).0.0" ;;
  minor) next="${major}.$((minor + 1)).0" ;;
  patch) next="${major}.${minor}.$((patch + 1))" ;;
  [0-9]*.[0-9]*.[0-9]*) next="$bump" ;;
  *) die "invalid bump '$bump' (use patch | minor | major | X.Y.Z)." ;;
esac
tag="v$next"

git rev-parse "$tag" >/dev/null 2>&1 && die "tag $tag already exists."
grep -q '^## \[Unreleased\]' CHANGELOG.md || die "no '## [Unreleased]' section in CHANGELOG.md."

# Release notes = the current [Unreleased] body (entries up to the next heading).
notes="$(awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f' CHANGELOG.md | sed '/^[[:space:]]*$/d')"
[[ -n "$notes" && "$notes" != "- Nothing yet." ]] \
  || die "[Unreleased] is empty — add entries before releasing."

today="$(date -u +%Y-%m-%d)"

if [[ "$dry_run" == 1 ]]; then
  printf 'release (dry-run): %s -> %s  (%s, %s)\n\n' "$cur" "$next" "$tag" "$today"
  printf 'Release notes:\n%s\n' "$notes"
  exit 0
fi

# Mutating preconditions — only enforced for a real release.
command -v gh >/dev/null 2>&1 || die "the gh CLI is required."
[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || die "not on main."
[[ -z "$(git status --porcelain)" ]] || die "working tree not clean — commit or stash first."

printf 'release: %s -> %s  (%s)\n' "$cur" "$next" "$tag"

# Roll the changelog: reset [Unreleased], insert the dated section, refresh links.
tmp="$(mktemp)"
awk -v ver="$next" -v date="$today" -v base="$BASE_URL" '
  /^## \[Unreleased\]/ {
    print; print ""; print "- Nothing yet."; print ""
    print "## [" ver "] - " date
    next
  }
  /^\[Unreleased\]:/ {
    print "[Unreleased]: " base "/compare/v" ver "...HEAD"
    print "[" ver "]: " base "/releases/tag/v" ver
    next
  }
  { print }
' CHANGELOG.md > "$tmp" && mv "$tmp" CHANGELOG.md

printf '%s\n' "$next" > VERSION

git add VERSION CHANGELOG.md
git commit --no-verify -m "🔖 chore(release): $tag"
git tag -a "$tag" -m "bootstrap-web-setup $tag"
git push origin main
git push origin "$tag"
gh release create "$tag" --title "$tag" --notes "$notes"

printf 'release: published %s -> %s/releases/tag/%s\n' "$tag" "$BASE_URL" "$tag"
