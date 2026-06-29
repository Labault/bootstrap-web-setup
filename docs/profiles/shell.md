# Profile: `shell`

For **Shell/Bash tooling repos** (bootstrap itself, server-setup, dotfiles…).
Inherits everything from [`minimal`](minimal.md) and adds shell-specific tooling:
`shfmt` formatting and a `bats` test harness wired into CI. A sibling of
[`symfony`](symfony.md) — both extend `minimal`.

## Required binaries

`minimal`'s binaries plus: `bats`, `shfmt`.

`shellcheck` is **not** repeated here — it already comes from `minimal`. Together
`shellcheck` + `shfmt` + `bats` are the shell trio this profile gates on.

## Files added (on top of `minimal`)

| File | Role |
| ---- | ---- |
| `tests/smoke.bats` | A trivial passing smoke test so `bats tests/` is green immediately (bats errors on an empty `tests/`) |
| `tests/test_helper.bash` | Shared bats helper (`REPO_ROOT`, common setup) loaded via `load test_helper` |
| `.github/workflows/tests.yml` | Shell CI: installs `bats` (pinned) and runs `bats tests/` |

It also **overrides** two `minimal` files with shell-aware versions:

- `.pre-commit-config.yaml` — adds a `shfmt` hook (excludes `.bats`, which shfmt
  can't parse) on top of the inherited shellcheck hook
- `Makefile` — adds `make test` (bats) and folds `shfmt` into `lint` (`shfmt -d`,
  a format check) and `fix` (`shfmt -w`), plus a `make fmt` target

## Formatting

`shfmt` reads the deposited `.editorconfig` for indentation (2-space for shell),
so no flags pin the width. The `shfmt` pre-commit hook formats in place (`-w`) and
pre-commit fails the commit if anything changed; `make lint` runs `shfmt -d` as a
non-mutating check.

## Detection

A repo is auto-detected as `shell` when it tracks `*.sh`/`*.bash` files and has
**no** `composer.json` or `package.json` (a manifest would pick `symfony` /
`fullstack` / `minimal` instead). The signal is **git-tracked** files only, so a
stray untracked script doesn't flip the profile.

## Parameters (locked)

- Required binaries **`bats`**, **`shfmt`** (added to the inherited `shellcheck`)
- `shfmt` driven by `.editorconfig` (2-space), `.bats` excluded from the hook
- CI runs `bats tests/`; the deposited smoke test passes from the first run
