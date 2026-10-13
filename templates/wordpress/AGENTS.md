# AGENTS.md

Shared conventions for this WordPress project. Claude Code imports this file
through `CLAUDE.md`; Codex reads it directly. Keep it committed so the rules do
not depend on which assistant happens to open the repository.

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

This profile targets WordPress project-owned code and uses Composer-local PHP
tools. `make cs` checks WordPress Coding Standards, `make stan` runs PHPStan,
and `make test` runs the configured PHPUnit suite. `make cs-fix` applies fixes.
Use the supported PHP/WordPress versions recorded by the project.

## Conventions

- Commits use Conventional Commits with a leading Gitmoji. The
  `scripts/lint-commit-msg.sh` hook validates the message format.
  Do not add an AI co-author trailer.
- Keep secrets out of source control; Gitleaks runs locally and in CI.
- Read `docs/README.md` when present and update affected documentation with the
  change. Keep project rules here and procedures in their canonical documents.

## Scope

- Never edit WordPress core. Core is a dependency, even when it lives in Git.
- Keep project-owned code in plugins, themes or must-use plugins with explicit
  boundaries.
- Prefer WordPress APIs over custom infrastructure when they solve the same
  problem clearly.
- Do not add a plugin or Composer package for a small amount of readable code.

## PHP

WordPress Coding Standards are the source of truth for formatting and naming.
Run `make cs` to check them and `make cs-fix` for safe automatic fixes. PHPStan
runs at level 9 through `make stan`.

- Use early returns to keep callbacks and request handlers flat.
- Keep hooks thin. Put business logic in focused functions or classes that can
  be tested without booting all of WordPress.
- Prefix global functions, options, transients and hook names. Namespaced code
  should still use explicit, stable identifiers at WordPress boundaries.
- Treat values returned by WordPress as the unions they really are. Check
  `WP_Error`, `false` and nullable results before using them.
- Do not hide PHPStan errors behind broad ignores. A narrow, documented ignore
  is acceptable only when a dynamic WordPress API cannot be modelled cleanly.

## Security

- Validate and sanitize input when it enters the system. Escape output for its
  exact context, as late as possible.
- A nonce protects intent, not authorization. Check the relevant capability as
  well.
- Prepare dynamic SQL with `$wpdb->prepare()`. Never interpolate request data
  into a query.
- Keep secrets and personal data out of source control and logs. Collect only
  the data the feature actually needs.

## Tests

Work in small red, green, refactor steps. A bug starts with a test that
reproduces it. Test project-owned behavior rather than WordPress internals.
