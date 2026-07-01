# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The current version
lives in the [`VERSION`](VERSION) file and is what `bootstrap --version` prints.

## [Unreleased]

### Added

- `make release` / `make release-preview`: a release workflow (`scripts/release.sh`)
  that bumps `VERSION`, rolls the changelog's `[Unreleased]` into a dated section,
  commits, tags `vX.Y.Z`, pushes, and creates the GitHub release. Repo-local
  targets live in an optional, unmanaged `Makefile.local`, loaded by the deposited
  Makefile via a new `-include Makefile.local` extension point.

### Changed

- markdownlint config gains `MD024: siblings_only` so a changelog can repeat
  `### Added` / `### Changed` once per version; EditorConfig's tab rule now covers
  `Makefile.*` and `*.mk`.

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
