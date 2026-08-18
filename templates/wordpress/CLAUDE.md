# CLAUDE.md

Project context for Claude Code. Enrich this file with the project’s actual
plugin, theme and deployment details.

Shared WordPress conventions live in `AGENTS.md` and are imported below.

@AGENTS.md

## Stack

- Language: PHP 8.3+
- Runtime: WordPress
- Custom code: <!-- plugins, themes, must-use plugins -->
- Datastore: MySQL or MariaDB through WordPress APIs

## Commands

Quality goes through `make`; PHP tools come from the project’s Composer install.

- `make qa`: run every configured quality check
- `make cs`: check WordPress Coding Standards
- `make cs-fix`: fix auto-fixable coding-standard violations
- `make stan`: run PHPStan at level 9
- `make test`: run PHPUnit when a suite is configured
- `make hooks`: install the pre-commit and commit-message hooks

## Project rules

<!-- Add domain rules, supported WordPress/PHP versions and deployment gotchas. -->
