# PHPStan policy

Bootstrap deposits **PHPStan level 9 without an automatic baseline** for PHP
profiles. Applying configuration is not evidence that the code passes analysis.
Run the project's quality gate and report its actual result.

## Default contract

- Symfony and fullstack analyze `src/` at level 9. Add other project-owned paths
  when needed. WordPress keeps its existing scope and framework-specific rules.
- No profile includes or creates a baseline by default. `apply` does not invoke
  PHPStan, even when Composer and the analyzer are already installed.
- `apply`, `reconcile` and CI never generate or refresh a baseline. Existing
  project-owned baseline files are not deleted or rewritten.
- Keep level 9. Do not lower it, add broad ignores or exclude project-owned code
  just to obtain a green gate. Level 9 is the chosen contract, not a claim that
  it is PHPStan's highest available level.

## Fix the cause first

Read the project's manifests, lockfile and effective PHPStan configuration.
Fix real code errors. For a suspected false positive, check the modelled types,
available framework extensions and stubs before proposing an ignore. Adding a
dependency still requires the project owner's approval.

A necessary false-positive suppression must be specific, justified and reviewed
in the project. It does not authorize a blanket ignore for the same error type.
Keep unused-ignore reporting enabled so obsolete suppressions are removed.

## Explicit legacy exception

A baseline is a temporary migration exception approved by the project owner,
not a bootstrap profile or a command-line mode. Before accepting one, record:

1. The analyzed scope, PHPStan version and effective configuration.
2. The existing diagnostics, their count and why immediate correction is deferred.
3. The approved scope and a concrete plan to reduce and remove the debt.

The project owns and versions the baseline, its deliberate inclusion in the
selected configuration, and the exception record. Local gates and CI must use
the same intended configuration. Generation is a separate, explicitly approved
project operation, followed by review of the resulting diff.

Do not regenerate the baseline to absorb new errors. Remove entries as the debt
is fixed. Any increase requires a new, justified decision; it must not happen
inside an installation, hook or CI run. A baseline matches diagnostics by file,
message and occurrence count, not by source line: unchanged counts alone do not
prove that changed code introduces no regression.

Report an analysis passing with approved suppressions as such, rather than
claiming that the code has no PHPStan errors.

## Existing projects

There is no automatic rollout. Before adopting this template change:

1. Identify the PHPStan configuration actually selected by the project's wrappers
   and CI, including any `phpstan.neon` override.
2. Preview `bootstrap reconcile --dry-run` and review the proposed diff.
3. The former template's baseline include may be removed. The baseline file stays
   on disk, but its diagnostics become visible when it is no longer included.
4. Fix the diagnostics, or agree on an explicit legacy exception before updating
   that project. Preserve local settings and resolve merge conflicts deliberately.
5. Run the appropriate gate. A successful reconcile is not a passing analysis.

Do not re-apply globally or delete baseline files merely because the new default
does not use them.

## Reference validation

The Symfony reference workflow runs the deposited PHPStan gate without generating
a baseline first. Formatting and Rector normalization remain confined to its
throwaway fixture. Analysis errors must fail the gate.

The isolated regression tests cover profile inheritance, absence of analyzer
execution, preservation of existing baselines, `--no-overwrite`, dry-run and
reconciliation from the former template.

PHPStan documents [baselines](https://phpstan.org/user-guide/baseline),
[ignores](https://phpstan.org/user-guide/ignoring-errors) and
[configuration selection](https://phpstan.org/config-reference#config-file).
