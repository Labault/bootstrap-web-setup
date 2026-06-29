| `scripts/lint-commit-msg.sh` | Commit-msg linter: gitmoji + Conventional Commits |actionlint, commit-msg lint |# Profile: `minimal`

The base layer for **any web repo**, language-agnostic. `symfony`, `shell` and
`fullstack` inherit everything here.

## Required binaries

Checked by `bootstrap doctor` (must be on your machine via mac-setup):

`git`, `pre-commit`, `gitleaks`, `shellcheck`, `actionlint`, `markdownlint-cli2`,
`lychee`, `editorconfig-checker`.

## Files deposited

| File | Role |
| ---- | ---- |
| `.editorconfig` | Indentation / EOL / charset across editors (2-space default, 4 for PHP) |
| `.gitignore` | Base ignores in a tagged `# >>> bootstrap` block (merged) |
| `.pre-commit-config.yaml` | Local-mode hooks: editorconfig, gitleaks, shellcheck, markdownlint, actionlint, commit-msg lint |
| `scripts/lint-commit-msg.sh` | Self-contained commit-msg linter: gitmoji + Conventional Commits |
| `.gitleaks.toml` | Secret-scanning config (extends the default ruleset) |
| `.shellcheckrc` | Shell lint config |
| `.markdownlint-cli2.yaml` | Markdown lint config |
| `lychee.toml` | Dead-link checker config |
| `Makefile` | `make qa` / `lint` / `fix` / `hooks` |
| `SECURITY.md`, `CONTRIBUTING.md`, `CLAUDE.md` | Project docs |
| `.vscode/extensions.json` | Recommended extensions (merged) |
| `.github/workflows/ci.yml` | Lint + dead-link CI |
| `.github/workflows/security.yml` | gitleaks + dependency review |
| `.github/dependabot.yml` | github-actions updates |
| `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*` | Issue/PR templates |

## Hooks

`pre-commit` is installed after deposit (`pre-commit` + `commit-msg` stages).
All hooks run in `local` mode — they call binaries from your machine, not pinned
remote repos.

## Notes

- The CI workflow runs the linters via marketplace actions (no local binaries
  needed on the runner); the same checks run locally through pre-commit.
- The `commit-msg` hook is a self-contained shell script — no extra binary needed.
