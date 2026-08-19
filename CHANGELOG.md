# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The current version
lives in the [`VERSION`](VERSION) file and is what `bootstrap --version` prints.

## [Unreleased]

### Added

- A `wordpress` profile for sites, plugins and themes: WPCS,
  PHPCompatibilityWP, PHPStan level 9 without a baseline, Rector, dedicated
  hooks, CI, Make targets, Composer updates and shared AI conventions.
  Auto-detection only fires on `wp-config.php` or a full core tree; custom
  layouts stay explicit instead of being guessed.
- `make release` / `make release-preview`: a release workflow (`scripts/release.sh`)
  that bumps `VERSION`, rolls the changelog's `[Unreleased]` into a dated section,
  commits, tags `vX.Y.Z`, pushes, and creates the GitHub release. Repo-local
  targets live in an optional, unmanaged `Makefile.local`, loaded by the deposited
  Makefile via a new `-include Makefile.local` extension point.

### Changed

- markdownlint config gains `MD024: siblings_only` so a changelog can repeat
  `### Added` / `### Changed` once per version; EditorConfig's tab rule now covers
  `Makefile.*` and `*.mk`.
- Deposited workflows (`ci.yml`, `security.yml`, `tests.yml`, `php.yml`,
  `front.yml`) now restrict their `push` trigger to `main`: pushing a PR branch
  no longer runs every workflow twice (push + pull_request).

### Fixed

- `.bootstrap.yaml` is written with mode 0644 instead of inheriting mktemp's
  0600 — the state file is meant to be committed, like every deposited file.
- `validation/run-all.sh` now runs under `set -uo pipefail`, aligned with
  server-setup's harness.
- The WordPress PHPCS core exclusions are anchored to the repository root, so
  `wp-content` is analyzed instead of being accidentally matched by
  `/wp-*.php`. PHPStan also loads its PHPUnit extension when analyzing tests.

### Security

- Profile names (`--profile` and `extends:` values) are validated against an
  allowlist (`^[a-z][a-z0-9-]*$`) before any path is built from them — back-port
  of server-setup's traversal hardening (its CHANGELOG 0.2.0).

## [0.5.0] - 2026-06-27

First tagged release. The CLI and its three profiles are complete, tested, and
documented.

### Changed

- **Commit-message linting is now a self-contained shell script.** bootstrap
  deposits `scripts/lint-commit-msg.sh` (gitmoji + Conventional Commits) wired as
  a `commit-msg` hook: pre-commit on `minimal`/`symfony`, Husky on `fullstack`.
  No npm dependency; the `minimal` profile now suggests no npm packages.
- Symfony defaults made internally consistent: PHP-CS-Fixer owns code style
  (`declare_strict_types`), Rector no longer fights it (`codingStyle` off), and
  the deprecated `strictBooleans` set was removed.

### Added

- `apply | doctor | reconcile | update | list | detect` commands, with
  `--dry-run` everywhere and a blocking required-binary guard (`doctor`).
- Profiles `minimal` / `symfony` / `fullstack` with inheritance and
  auto-detection; collision handling (merge `.gitignore` & `extensions.json`,
  backup+replace otherwise); `.bootstrap.yaml` state; drift detection and a
  3-way-merge `reconcile`.
- A bats unit suite and a black-box acceptance harness (`validation/`), both run
  in CI; a `Reference` workflow proving the deposited Symfony pipeline runs green.
- README/docs with hand-authored SVG diagrams and terminal demos; a cross-link
  with [mac-dev-setup](https://github.com/Labault/mac-dev-setup).

### Rejected

- Intensity levels (`--level` light/standard/strict): see
  [`docs/proposals/intensity-levels.md`](docs/proposals/intensity-levels.md). The
  project keeps a single, highest-intensity baseline.

[Unreleased]: https://github.com/Labault/bootstrap-web-setup/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/Labault/bootstrap-web-setup/releases/tag/v0.5.0
