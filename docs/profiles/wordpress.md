# Profile: `wordpress`

For WordPress sites, plugins and themes. It inherits
[`minimal`](minimal.md), then adds a PHP quality stack built for WordPress. It
does not inherit `symfony`: forcing `@Symfony` and Symfony project rules onto
WordPress would create a very tidy argument between incompatible tools.

## Required binaries

`minimal`'s binaries plus `php` and `composer`.

PHPCS, WordPress Coding Standards, PHPCompatibilityWP, PHPStan, PHPUnit and Rector
live in the project's `vendor/bin`. `bootstrap apply` prints the commands to
allow WPCS's Composer installer and add the missing packages. It never edits
`composer.json`.

## Files added

| File | Role |
| ---- | ---- |
| `phpcs.xml.dist` | Complete `WordPress` ruleset, scoped away from core, dependencies, uploads and caches |
| `phpstan.dist.neon` | PHPStan level 9 with WordPress and strict PHPUnit rules, without a baseline |
| `rector.php` | PHP 8.3 and quality refactorings, checked in dry-run mode |
| `.github/workflows/wordpress.yml` | Composer install, PHPCS, PHPStan, Rector and an optional PHPUnit suite on PHP 8.3 |
| `AGENTS.md` | Shared WordPress, security and testing conventions for AI collaborators |

The profile also overrides five files from `minimal`:

- `.editorconfig` switches PHP indentation from PSR-12 spaces to WPCS tabs;
- `.pre-commit-config.yaml` adds project-local PHPCS, PHPStan and Rector hooks;
- `Makefile` adds `cs`, `cs-fix`, `rector`, `rector-fix`, `stan` and optional
  `test` targets;
- `.github/dependabot.yml` adds Composer updates;
- `CLAUDE.md` imports the shared `AGENTS.md` and records the WordPress stack.

## Install the suggested dependencies

WPCS registers its rules through a Composer plugin. Composer 2.2 and later need
that plugin to be explicitly allowed before installation. `apply` prints both
commands in the right order:

```sh
composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer require --dev phpcompatibility/phpcompatibility-wp phpstan/phpstan phpstan/phpstan-phpunit phpunit/phpunit rector/rector szepeviktor/phpstan-wordpress wp-coding-standards/wpcs
```

## Detection

Auto-detection chooses `wordpress` for either of these strong signals:

- a `wp-config.php` file;
- the three core directories `wp-admin`, `wp-content` and `wp-includes`.

A lone `wp-content` directory is not enough. Plugins, themes and Bedrock layouts
vary too much to detect without guessing, so select them explicitly:

```sh
bootstrap apply --profile wordpress
```

## Scope and customization

The default PHPCS, PHPStan and Rector configs scan the repository, then exclude
WordPress core, Composer and Node dependencies, uploads, caches, languages and
upgrade artifacts. Core exclusions are anchored to the repository root so they
never swallow project-owned `wp-content` code. Narrow the paths in the deposited
configs when the repo also vendors third-party plugins or themes. Bootstrap gives
you a strict baseline; it cannot guess which part of `wp-content` you wrote at
23:47 last Tuesday.

Unlike the Symfony profile, WordPress never creates a PHPStan baseline. The
profile targets greenfield projects, so level 9 starts clean and stays clean.
PHPUnit's base assertion classes are scanned explicitly because recent PHPStan
stubs otherwise lose inherited static assertions in some dependency layouts.

PHPUnit runs only when `vendor/bin/phpunit` exists. The profile does not scaffold
a fake test suite because a site, plugin and theme need different WordPress
bootstraps. No theatre: `make test` states clearly when no suite is configured.
