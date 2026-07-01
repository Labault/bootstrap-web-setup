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
| `phpstan.dist.neon` | PHPStan at **level 9**, includes `phpstan-baseline.neon` |
| `.php-cs-fixer.dist.php` | PHP-CS-Fixer with the `@Symfony` ruleset |
| `rector.php` | Rector with PHP 8.4 + all prepared sets (CI runs dry-run) |
| `.hadolint.yaml` | Dockerfile lint config |
| `.github/workflows/php.yml` | PHP CI: composer install, CS dry-run, PHPStan, Rector dry-run, tests |

It also **overrides** three `minimal` files with PHP-aware versions:

- `.pre-commit-config.yaml`: adds `php-cs-fixer`, `phpstan`, `rector`, `hadolint` hooks
- `Makefile`: adds `cs`, `cs-fix`, `stan`, `rector`, `rector-fix`, `test`, `fix`
- `.github/dependabot.yml`: adds the `composer` ecosystem

## PHPStan baseline

On an **existing** project (a `composer.json` is present), `apply` generates
`phpstan-baseline.neon` so level 9 doesn't break a legacy codebase. If PHPStan
isn't available yet, an empty baseline is written and the command to generate it
later is printed.

## Parameters (locked)

- PHP **8.4** only in CI (no matrix)
- PHPStan **level 9** with auto baseline on existing projects
- PHP-CS-Fixer ruleset **`@Symfony`**
- Rector **all sets** (dry-run in CI; fix locally with `make rector-fix`)
