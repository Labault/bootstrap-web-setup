# AGENTS.md

Shared development guidance for bootstrap-web-setup, imported by `CLAUDE.md`.

## Project

A Bash 4+ CLI that deposits quality, CI and security configuration. It never
installs binaries or edits a project's dependency manifests. The current
architecture and profile contracts are mapped in [docs/README.md](docs/README.md).

## Commands

- `make test`: run the Bats suite with isolated temporary projects.
- `bats tests/<file>.bats`: run one behavior while iterating.
- `make lint`: run pre-commit hooks and a shfmt check; inspect hook effects first.
- `make qa`: lint and tests.
- `make fix`: run automatic formatting and hook corrections.
- `bash validation/run-all.sh`: run the black-box acceptance suite.

Do not run the heavyweight smoke harnesses without inspecting their setup:
they install tools in throwaway projects. Changes to generated files belong in
`templates/` and their profile manifests, with an apply/reconcile regression test.

## Invariants

- Logs go to stderr; stdout stays usable as data.
- Preserve dry-run, idempotence, backups and collision behavior.
- Profile inheritance resolves overrides by destination: the child wins.
- YAML manifests use the existing Bash/awk parser. Do not add a YAML dependency.
- Reconcile performs a three-way merge using the recorded template revision.
- Shared agent guidance belongs in AGENTS.md; CLAUDE.md imports it.
- Use Gitmoji + Conventional Commits and never add an AI co-author trailer.
