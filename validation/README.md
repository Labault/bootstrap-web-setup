# Validation harness

A black-box acceptance suite for the `bootstrap` CLI. One folder per case, each
exercising a feature **when it works** and **when it must fail cleanly**. Every
case sets up an isolated workspace, runs the command, checks a criterion, and
writes its own `RESULT.txt` (`PASS`/`FAIL`) and `output.log`.

This complements the unit-style `tests/` (bats): here we drive the real CLI
end to end and assert on its observable behaviour.

The two `smoke-*-hooks.sh` scripts (top-level, **not** part of `run-all.sh`) are
separate, heavier end-to-end checks. Each scaffolds a throwaway project, deposits
a profile, installs the **latest** tools from the package manager, and runs the
deposited hooks/gates for real on a clean fixture — so a hardcoded command that
drifts against a floating binary fails here, not in the next bootstrapped project:

- `smoke-php-hooks.sh` — `symfony` profile; runs the php-cs-fixer / phpstan /
  rector pre-commit hooks. Needs PHP, Composer and `pre-commit`.
- `smoke-js-hooks.sh` — `fullstack` profile; runs the eslint / prettier / tsc /
  lint-staged front gates. Needs Node and npm.

They need a real language toolchain, so each runs in its own CI job rather than
the no-PHP/no-Node acceptance suite.

## Requirements

- bash 4+
- `git` and `jq` (used by `apply` / `reconcile`)

Cases pass `--skip-bin-check`, so the full lint toolchain is **not** required to
validate the logic.

## Usage

```sh
cd validation

# Run everything (summary table at the end):
./run-all.sh

# Run a subset by name prefix:
./run-all.sh 04 14 50

# Run a single case and read its trace:
bash cases/53-fail-invalid-json/run.sh
cat  cases/53-fail-invalid-json/output.log
```

If your checkout isn't at the default path:

```sh
export BOOTSTRAP_REPO=/path/to/bootstrap-web-setup
```

## Reading a result

- `RESULT.txt` — `PASS` (all assertions held) or `FAIL (n)`.
- `output.log` — the command, its output, its exit code, then each assertion.

For the `50…`–`75…` cases (prefix `fail-`), **`PASS` means the tool failed
correctly**: it stopped, printed a clear message, and lost/overwrote nothing.

## Layout

```text
validation/
├── README.md
├── run-all.sh        runs all cases, prints a summary
├── _lib.sh           shared setup / assertions / verdict
└── cases/
    ├── 01-list … 24-dry-run-collision      (nominal: it works)
    └── 50-fail-… … 75-strict-drift-exits   (robustness: it fails cleanly)
```

Generated artifacts (`.work/`, `.backups/`, `RESULT.txt`, `output.log`) are
git-ignored.
