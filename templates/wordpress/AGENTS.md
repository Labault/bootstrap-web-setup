# AGENTS.md

Shared conventions for this WordPress project. Claude Code imports this file
through `CLAUDE.md`; Codex reads it directly. Keep it committed so the rules do
not depend on which assistant happens to open the repository.

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
