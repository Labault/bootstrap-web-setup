# Symfony reference project

A tiny PHP project used by the `Reference` CI workflow to prove the **deposited
symfony pipeline actually runs green** on a real codebase.

The workflow:

1. copies this folder to a scratch dir and `git init`s it,
2. runs `bootstrap apply --profile symfony` on it,
3. `composer install`s the dev tools,
4. normalizes the tree (`php-cs-fixer fix`, `rector process`) in the scratch dir,
5. runs the deposited quality gates: `php-cs-fixer --dry-run`, `phpstan`,
   `rector --dry-run`, `phpunit`, which must all pass.

Only the source files (`composer.json`, `src/`, `tests/`, `phpunit.xml.dist`) are
committed here; everything else is deposited by bootstrap in CI.

PHPStan runs at level 9 without a baseline. Its errors must fail the gate;
the workflow never snapshots them into suppressions. See the
[PHPStan policy](../../docs/phpstan-policy.md).
