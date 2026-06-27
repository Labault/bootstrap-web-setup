#!/usr/bin/env bash
# Smoke test: the deposited PHP pre-commit hooks, run for real against the
# latest Composer tools.
#
# WHY THIS EXISTS
#   bootstrap is a shell repo, so the PHP hooks it deposits (php-cs-fixer,
#   phpstan, rector) never actually execute anywhere until they land in a real
#   project. Their commands are hardcoded in the template while the binaries
#   float in vendor/bin — when a flag moves between tool versions, the hook
#   breaks SILENTLY on the next bootstrapped project. That is exactly how the
#   rector `--no-progress` / `--no-progress-bar` drift slipped through.
#
#   This test scaffolds a throwaway Symfony project, deposits the `symfony`
#   profile with the real `bootstrap apply`, installs the *latest* PHP tools
#   from Composer (floating versions, on purpose), and runs the deposited hooks
#   for real. Flag drift — or a cs-vs-rector config regression — fails HERE,
#   before it reaches anyone's project.
#
# SCOPE
#   The PHP hooks only. The language-agnostic hooks (shellcheck, gitleaks,
#   actionlint, markdownlint, editorconfig-checker) are already exercised
#   continuously by this repo's own ci.yml against real files, so they are not
#   re-run here. The fullstack JS hooks are a natural follow-up, not covered yet.
#
# REQUIRES on PATH: php (8.4+), composer, pre-commit, git, jq.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BS="$REPO/bin/bootstrap"

log()  { printf '\033[1;34m▸\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

for bin in php composer pre-commit git jq; do
  command -v "$bin" >/dev/null 2>&1 || fail "missing required tool: $bin"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PROJ="$WORK/smoke"
mkdir -p "$PROJ/src"
cd "$PROJ"

log "scaffolding a throwaway Symfony project in $PROJ"
git init -q
git config user.email smoke@example.com
git config user.name 'bootstrap smoke'

cat > composer.json <<'JSON'
{
    "name": "bootstrap/smoke-fixture",
    "description": "Throwaway project for the bootstrap PHP-hook smoke test.",
    "require-dev": {},
    "config": {
        "sort-packages": true
    }
}
JSON

# An intentionally inert fixture: a fixed point under @Symfony:risky (php-cs-fixer),
# PHPStan level 9, and the rector sets in rector.php. The tools should want no
# changes; if a future version does, that surfaces here rather than silently.
cat > src/Smoke.php <<'PHP'
<?php

declare(strict_types=1);

namespace App;

final class Smoke
{
    public function ping(): string
    {
        return 'pong';
    }
}
PHP

log "depositing the symfony profile via 'bootstrap apply'"
"$BS" apply --target "$PROJ" --profile symfony --skip-bin-check >&2

# Regression guard tied to the flags this test was born from: the deposited hook
# must carry them. Catches a bad template edit even before the tools run.
grep -q -- '--no-progress-bar' .pre-commit-config.yaml \
  || fail "deposited rector hook is missing --no-progress-bar"
grep -q -- '--path-mode=intersection' .pre-commit-config.yaml \
  || fail "deposited php-cs-fixer hook is missing --path-mode=intersection"
ok "deposited hook flags are present"

log "installing the latest PHP tools from Composer (floating versions)"
composer require --dev --no-interaction --no-progress \
  phpstan/phpstan friendsofphp/php-cs-fixer rector/rector >&2

# The deposited hooks call bare binaries; a real bootstrapped project keeps
# vendor/bin on PATH (see the .pre-commit-config.yaml header). Mirror that.
export PATH="$PROJ/vendor/bin:$PATH"

git add -A

# Run the deposited hooks on the clean tree and require zero modifications. We do
# NOT pre-settle: every PHP file present is either a deposited template or the
# inert fixture, all of which must already be fixed points of the very ruleset
# they ship with. A red here therefore means one of two real regressions:
#   - a hook flag drifted against a new tool version (the bug this test exists for), or
#   - a shipped template / the fixture stopped being clean under a new tool version
#     and needs re-settling.
log "running the deposited PHP hooks for real"
hooks_failed=0
for hook in php-cs-fixer phpstan rector; do
  if pre-commit run "$hook" --all-files >&2; then
    ok "hook '$hook' is green"
  else
    printf '\033[1;31m✗ hook %s failed\033[0m\n' "$hook" >&2
    hooks_failed=1
  fi
done

[[ "$hooks_failed" -eq 0 ]] \
  || fail "a deposited PHP hook failed — flag drift or a template regression"

ok "all deposited PHP hooks are green against the latest tools"
