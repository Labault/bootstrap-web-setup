# Shell reference project

A tiny Bash project used by the `Reference` CI workflow to prove the **deposited
shell gates actually run green** on a real codebase.

The workflow:

1. copies this folder to a scratch dir and `git init`s it,
2. runs `bootstrap apply --profile shell` on it (deposits the bats harness, the
   `tests.yml` workflow, the shfmt-aware pre-commit config and Makefile),
3. runs the deposited gates — `shellcheck`, `shfmt -d`, and the bats suite
   (`make test`) — which must all pass.

Only the source files (`bin/`, `lib/`, `tests/greet.bats`) are committed here;
the bats helper (`tests/test_helper.bash`), the smoke test and the rest of the
config are deposited by bootstrap in CI. `tests/greet.bats` loads the deposited
helper and uses its `REPO_ROOT` to locate `bin/greet`, so the reference also
proves the deposited harness is usable by real tests.
