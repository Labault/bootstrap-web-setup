# bootstrap-web-setup

A Bash CLI — companion to **mac-setup** — that drops a standardized
quality/CI/security configuration layer into any web project (Symfony,
optionally with a JS/TS front), new or existing.

**Guiding principle (non-negotiable):** bootstrap deposits **config files only**.
It never installs binaries — those come from your machine setup (mac-setup). A
config without its tool is a dead file, so `bootstrap doctor` checks the required
binaries are present before anything is written.

## Requirements

- bash 4+ (`brew install bash` — macOS ships 3.2)
- git, and the tools each profile needs (see `bootstrap doctor`)
- `jq` (used for JSON merges)

## Install

```sh
git clone https://github.com/Labault/bootstrap-web-setup.git
cd bootstrap-web-setup
./install.sh            # symlinks `bootstrap` into ~/.local/bin (override with BOOTSTRAP_BIN_DIR)
```

Make sure the target directory is on your `PATH`. Then:

```sh
bootstrap --help
```

## Usage

```sh
bootstrap doctor                 # check the required binaries for the detected profile
bootstrap apply                  # deposit the (auto-detected) profile into the current dir
bootstrap apply --profile symfony
bootstrap apply --dry-run        # preview, write nothing
bootstrap list                   # list profiles and what they deposit
bootstrap update                 # update bootstrap itself (never touches projects)
```

Every mutating command supports `--dry-run`. `apply` also takes `--target <dir>`,
`--no-overwrite` and `--skip-bin-check`.

## Profiles

| Profile     | For                          | Adds on top of its parent |
| ----------- | ---------------------------- | ------------------------- |
| `minimal`   | Any web repo (language-agnostic) | pre-commit, editorconfig, commitlint, gitleaks, shellcheck, markdownlint, actionlint, lychee, base CI/security workflows, Dependabot, transverse files |
| `symfony`   | PHP/Symfony                  | PHPStan, PHP-CS-Fixer, Rector, hadolint, PHP CI, PHP make targets |
| `fullstack` | Symfony + JS/TS front        | ESLint, Prettier, Husky + lint-staged, front CI |

Auto-detection: `composer.json` → `symfony`; `+ package.json` → `fullstack`;
otherwise `minimal`. Override with `--profile`.

See the per-profile pages in [docs/profiles/](docs/profiles/).

## How it behaves

- **New vs existing projects:** absent files are written; identical files are a
  no-op (idempotent); `.gitignore` and `.vscode/extensions.json` are merged;
  other existing files are backed up then replaced (or skipped with
  `--no-overwrite`).
- **Backups:** anything overwritten is copied to
  `~/Documents/Backups/bootstrap/<project>/<timestamp>/` first.
- **State:** each `apply` writes `.bootstrap.yaml` (profile, version, files +
  hashes) — the trace that will enable drift detection later.
- **Hooks:** `pre-commit` is installed after deposit (Husky on `fullstack`).
- **Manifests:** bootstrap never edits `composer.json` / `package.json`; it only
  suggests the `composer require --dev` / `npm install -D` lines to run.

## License

MIT — see [LICENSE](LICENSE).
