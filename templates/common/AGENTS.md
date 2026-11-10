# AGENTS.md

Shared project guidance for Codex and Claude Code, imported by `CLAUDE.md`.

## Stack

Use the project's manifests and lockfiles for the installed languages, framework
versions and dependencies. Read its README and deployment configuration for the
runtime and datastore; do not infer them from the bootstrap profile alone.

## Commands

Read the Makefile, any Makefile.local and the CI before running checks. The
project's wrappers define the runtime; machine tools and project-local tools
are provisioned separately, not installed by bootstrap.

- `make qa`: run the configured quality gate.
- `make lint`: run all configured pre-commit hooks; check their effects first.
- `make fix`: apply automatic corrections.
- `make hooks`: install pre-commit and commit-message hooks.

For an audit, use the available dry-run checks. Do not implicitly run automatic
fixes, migrations or destructive resets. Never bypass hooks to obtain a pass.

## Conventions

- Commits use Conventional Commits with a leading Gitmoji. The
  `scripts/lint-commit-msg.sh` hook validates the message format.
  Do not add an AI co-author trailer.
- Keep secrets out of source control; Gitleaks runs locally and in CI.
- Read `docs/README.md` when present and update affected documentation with the
  change. Keep project rules here and procedures in their canonical documents.
