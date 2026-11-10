# Profile: `symfony`

For **PHP/Symfony** projects. Inherits everything from
[`minimal`](minimal.md) and adds PHP tooling.

## Required binaries

`minimal`'s binaries plus: `php`, `composer`, `hadolint`.

PHPStan, PHP-CS-Fixer and Rector are **not** required binaries: they live in the
project's `vendor/bin` (installed via Composer). `bootstrap apply` prints the
`composer require --dev` line to add them; it never edits `composer.json`.

## Files added (on top of `minimal`)

| File | Role |
| ---- | ---- |
| `phpstan.dist.neon` | PHPStan at **level 9**, without a baseline |
| `.php-cs-fixer.dist.php` | PHP-CS-Fixer with the `@Symfony` ruleset |
| `rector.php` | Rector with PHP 8.4 + the prepared sets except the deprecated `naming` (CI runs dry-run) |
| `.hadolint.yaml` | Dockerfile lint config |
| `.github/workflows/php.yml` | PHP CI: composer install, CS dry-run, PHPStan, Rector dry-run, tests against PostgreSQL |

It also **overrides** shared `AGENTS.md` with PHP style conventions and keeps
`CLAUDE.md` as an import. Context and commands belong in `AGENTS.md`, so every
client receives the same guidance. Other PHP-aware overrides:

- `.gitignore`: versions `.env` (Symfony keeps documented defaults there) and
  ignores only `.env.local` / `.env.*.local`
- `.pre-commit-config.yaml`: adds `php-cs-fixer`, `phpstan`, `rector` (called
  from `vendor/bin`, no `PATH` setup needed) and `hadolint` hooks
- `Makefile`: adds `cs`, `cs-fix`, `stan`, `rector`, `rector-fix`, `test`, `fix`
- `.github/dependabot.yml`: adds the `composer` ecosystem

## PHPStan policy

`apply` deposits the level 9 configuration without creating a baseline or
running PHPStan. Existing baseline files remain project-owned and untouched.
Fullstack inherits this contract.

The [shared PHPStan policy](../phpstan-policy.md) defines explicit legacy
exceptions and the review required before reconciling an existing project.
Removing the former template include can expose existing diagnostics; no
automatic rollout or debt suppression is performed.

## Test database in CI

`php.yml` starts a `postgres:18-alpine` service and sets `DATABASE_URL` to
`postgresql://app:!ChangeMe!@127.0.0.1:5432/app?serverVersion=18&charset=utf8`,
the Symfony recipe's throwaway credentials. Doctrine's `dbname_suffix` turns
`app` into `app_test` in the test env. Before the tests, CI runs
`doctrine:database:create --if-not-exists` then
`doctrine:migrations:migrate --allow-no-migration`, both with `--env=test`.

Each step runs only when its command is registered: a project without
DoctrineBundle or without DoctrineMigrationsBundle still passes, at the cost of
an unused service container. To move to another PostgreSQL major, change the
image tag and `serverVersion` together.

## Parameters (locked)

- PHP **8.4** only in CI (no matrix)
- PostgreSQL **18** service for the tests
- PHPStan **level 9**, without an automatic baseline
- PHP-CS-Fixer ruleset **`@Symfony`**
- Rector **all prepared sets except `naming`**, deprecated upstream (dry-run in CI; fix locally with `make rector-fix`)
- PHP-CS-Fixer **>= 3.76**: the config allows newer PHP runtimes with
  `setUnsupportedPhpVersionAllowed(true)` instead of `PHP_CS_FIXER_IGNORE_ENV`
