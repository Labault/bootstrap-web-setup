#!/usr/bin/env bash
# Smoke test: the deposited front-end gates (fullstack profile), run for real
# against the latest npm tools.
#
# WHY THIS EXISTS
#   Same failure mode as smoke-php-hooks.sh, on the JS side. The fullstack
#   profile hardcodes commands — `npx eslint .`, `npx prettier --check .`,
#   `npx tsc --noEmit`, `npx lint-staged` — while the binaries float in
#   node_modules/.bin. When a flag moves or a flat-config API changes between
#   versions, the gate breaks silently on the next bootstrapped front project.
#
#   This scaffolds a throwaway fullstack project, deposits the `fullstack`
#   profile, installs the *latest* front tools from npm, and runs the deposited
#   gates for real on a clean fixture, requiring zero complaints.
#
# SCOPE
#   The front-end gates only (eslint / prettier / tsc / lint-staged), exactly as
#   front.yml and the Husky pre-commit hook invoke them, plus the deposited
#   Makefile front targets (`make front` / `make front-fix`). The PHP hooks are
#   covered by smoke-php-hooks.sh; the language-agnostic hooks by this repo's
#   own ci.yml.
#
# REQUIRES on PATH: node (20+), npm, git.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BS="$REPO/bin/bootstrap"

log() { printf '\033[1;34m▸\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[1;32m✓\033[0m %s\n' "$*" >&2; }
fail() {
  printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2
  exit 1
}

for bin in node npm git jq make; do
  command -v "$bin" >/dev/null 2>&1 || fail "missing required tool: $bin"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PROJ="$WORK/smoke"
mkdir -p "$PROJ/assets"
cd "$PROJ"

log "scaffolding a throwaway fullstack project in $PROJ"
git init -q
git config user.email smoke@example.com
git config user.name 'bootstrap smoke'

# composer.json + package.json make this a fullstack project; we force the
# profile anyway so the test is deterministic.
cat >composer.json <<'JSON'
{
    "name": "bootstrap/smoke-fixture",
    "description": "Throwaway project for the bootstrap front-hook smoke test.",
    "require-dev": {}
}
JSON

cat >package.json <<'JSON'
{
    "name": "bootstrap-smoke-fixture",
    "version": "0.0.0",
    "private": true,
    "type": "module"
}
JSON

# An intentionally inert TS fixture: clean under the strict tsconfig, the
# type-aware ESLint flat config, and Prettier's deposited .prettierrc. It lives
# in assets/ because that is what tsconfig.json includes.
cat >assets/app.ts <<'TS'
export function greet(name: string): string {
  return `hello, ${name}`;
}
TS

log "depositing the fullstack profile via 'bootstrap apply'"
"$BS" apply --target "$PROJ" --profile fullstack --skip-bin-check >&2

# The deposited Husky hook must be wired (it is the front git-hook entry point).
[[ -f .husky/pre-commit ]] || fail "fullstack apply did not deposit .husky/pre-commit"
[[ -f eslint.config.js ]] || fail "fullstack apply did not deposit eslint.config.js"
ok "fullstack config deposited (husky + eslint flat config)"

log "installing the latest front tools from npm (floating versions)"
npm install --no-audit --no-fund --save-dev \
  eslint @eslint/js typescript typescript-eslint globals prettier husky lint-staged >&2

git add -A

# Run the deposited gates exactly as front.yml and the Husky hook invoke them,
# on the clean tree, and require zero complaints. A red here means a hardcoded
# command drifted against a new tool version, or a deposited file stopped being
# clean under one — both real regressions worth catching before a project does.
log "running the deposited front gates for real"
gates_failed=0
run_gate() { # <label> <cmd...>
  local label="$1"
  shift
  if "$@" >&2; then
    ok "gate '$label' is green"
  else
    printf '\033[1;31m✗ gate %s failed\033[0m\n' "$label" >&2
    gates_failed=1
  fi
}

run_gate "tsc --noEmit" npx --no-install tsc --noEmit
run_gate "eslint ." npx --no-install eslint .
run_gate "prettier --check" npx --no-install prettier --check .
run_gate "lint-staged" npx --no-install lint-staged

# The same front tools, but driven through the deposited Makefile, to cover the
# qa/lint/fix wiring, not just the raw commands. (`make fix`/`make qa` also
# pull in php-cs-fixer/rector/pre-commit, absent from this PHP-less fixture, so
# we exercise the front-only targets.)
run_gate "make front" make front
run_gate "make front-fix" make front-fix

[[ "$gates_failed" -eq 0 ]] ||
  fail "a deposited front gate failed — flag/API drift or an unclean deposited file"

ok "all deposited front gates are green against the latest tools"
