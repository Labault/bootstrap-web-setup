# Profile: `fullstack`

For **Symfony + JS/TS front** projects. Inherits everything from
[`symfony`](symfony.md) (and therefore [`minimal`](minimal.md)) and adds the
front tooling.

## Required binaries

`symfony`'s binaries plus: `node`.

ESLint, Prettier, Husky and lint-staged live in the project's `node_modules` —
`apply` prints the `npm install -D` line to add them; it never edits
`package.json`.

## Files added (on top of `symfony`)

| File | Role |
| ---- | ---- |
| `eslint.config.js` | ESLint flat config (ESLint 9+) |
| `.prettierrc` | Prettier config |
| `.prettierignore` | Paths Prettier skips |
| `.lintstagedrc.json` | lint-staged rules (standalone file — `package.json` is untouched) |
| `.husky/pre-commit`, `.husky/commit-msg` | Husky hook scripts |
| `.github/workflows/front.yml` | Front CI: install, ESLint, Prettier check |

It also **overrides** `.github/dependabot.yml` to add the `npm` ecosystem.

## Hooks: Husky owns the git hooks here

To avoid running two git-hook managers at once, on `fullstack` **Husky is the
single git-hook entry point** (`core.hooksPath=.husky`). Its `pre-commit` script
delegates:

1. `lint-staged` — auto-fix staged front files (ESLint + Prettier)
2. `pre-commit run` — the repo-wide and PHP checks, reusing the pre-commit
   framework's hook definitions

The `commit-msg` hook runs `scripts/lint-commit-msg.sh`. `bootstrap apply` wires this by setting
`core.hooksPath` and making the scripts executable.
