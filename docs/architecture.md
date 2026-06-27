# Architecture

How the `bootstrap` CLI is built — a small, layered Bash codebase with no runtime
dependency beyond `git` and `jq`.

![bootstrap CLI architecture: bin/bootstrap is the dispatcher (global flags, bash 4+ guard); it sources lib/common.sh and dispatches to one lib/cmd_NAME.sh module per command (apply, doctor, reconcile, update, list); those drive the engine libraries (manifest, detect, merge, apply, state, state_read, drift, reconcile, bincheck), which read the profile manifests in profiles/ and the files to deposit in templates/](assets/images/cli-architecture.svg)

## The pieces

- **`bin/bootstrap`** — the entry point. Resolves its own location (symlink-safe),
  guards against bash < 4, parses the global flags (`--dry-run`, `--help`,
  `--version`), and dispatches to the right command module.
- **`lib/common.sh`** — shared foundation: colored logging (to stderr, so stdout
  stays clean for data), the `--dry-run` switch, `die`, and small helpers.
- **`lib/cmd_<name>.sh`** — one module per command (`apply`, `doctor`,
  `reconcile`, `update`, `list`, plus the auxiliary `detect`). Each parses its own
  options and orchestrates the engine.
- **The engine (`lib/`)** — the reusable building blocks:
  - `manifest` / `detect` — read profile manifests and resolve inheritance + the
    detected profile.
  - `merge` — the `.gitignore` and `extensions.json` merge strategies.
  - `apply` — the deposit engine (write / no-op / backup + replace / merge).
  - `state` / `state_read` — write and read `.bootstrap.yaml`.
  - `drift` — compare a project's state against the current templates.
  - `reconcile` — the 3-way merge.
  - `bincheck` — the required-binary guard.
- **`profiles/*.yaml`** — declarative manifests (`extends`, `requires_bin`,
  `files`, `suggest_*`). Adding a profile is data, not code.
- **`templates/`** — the actual files deposited into projects, organized by
  profile family (`common/`, `symfony/`, `fullstack/`).

## Conventions

- **Logs to stderr, data to stdout** — commands can be piped/scripted.
- **`set -euo pipefail`** everywhere; file-deposit functions report through a
  global and are called directly (never in `$()`) so write failures can't be
  swallowed.
- **shellcheck-clean**, portable (BSD/GNU), and self-applied — the repo runs the
  very `minimal` profile it ships.
