# Proposal: intensity levels (Phase 2)

**Status:** REJECTED. Decision: keep a **single, highest-intensity baseline** for
all tools: no `--level`, no light/standard/strict variants. The opinionated
strict config is the product's identity; configurability would dilute it. Kept
here as a record of the analysis in case the need ever resurfaces.
**Author:** project maintainer.
**Relates to:** [`../cahier-des-charges-bootstrap.md`](../cahier-des-charges-bootstrap.md)
(locked params), the `apply` / `doctor` / `reconcile` lifecycle.

## Problem

bootstrap ships **one opinionated baseline** (PHP 8.4, PHPStan level 9, Rector
broad sets, `@Symfony:risky`, blocking-ish CI). That is great for a serious app
but heavy for a prototype, a throwaway repo, or a team easing into static
analysis. People then hand-lower the config, which drifts and defeats the point.

The ask: offer a few **intensity levels** (e.g. light / standard / strict) so the
*same* baseline can be dialed up or down without forking it.

## Key insight: this is a second, orthogonal axis

Today's `minimal / symfony / shell / fullstack` is the **scope** axis (stack →
which tools). Intensity is a **different** axis (how strict), orthogonal to scope:

```text
            light        standard(*)      strict
minimal      …              …               …
symfony      …              …               …
shell        …              …               …
fullstack    …              …               …
            (*) = today's behaviour, the default
```

It is **not** a replacement for profiles: `light` is not "instead of `symfony`",
it is `symfony × light`. The two must stay separate concepts.

## Scope of this proposal

- Exactly **three levels**: `light`, `standard`, `strict`. No 5-level ladder.
- **`standard` is the default and is byte-for-byte today's output**: zero change
  for anyone who doesn't opt in.
- Only the **handful of intensity-sensitive files** get level variants. Every
  other deposited file is level-agnostic and is deposited unchanged.

### Intensity-sensitive files

| File | `light` | `standard` (today) | `strict` |
| --- | --- | --- | --- |
| `phpstan.dist.neon` | level 5 | level 9 + auto baseline | level 9 + `phpstan-strict-rules` + `bleedingEdge` |
| `rector.php` | `php` + `deadCode` only | quality/upgrade sets (current) | + all sets, no baseline |
| `.php-cs-fixer.dist.php` | `@Symfony` | `@Symfony:risky` (current) | + house rules |
| `.pre-commit-config.yaml` | format only | + lint + secrets (current) | + run on the whole history |
| CI (`ci.yml`, `php.yml`, `front.yml`) | lint informative | lint + security (current) | blocking gates + matrix / coverage |

Everything else (`.editorconfig`, `Makefile`, `SECURITY.md`, `dependabot.yml`,
templates, issue/PR templates, …) is identical across levels.

## Mechanism: `--level`, with per-file variants

Prefer a dedicated **`--level` flag** over modelling levels as `extends` profiles
(which would explode the profile namespace, `symfony-strict`, `fullstack-light`,
…, and confuse detection). Level is its own axis, so give it its own flag.

Proposed convention, minimal blast radius:

- A deposited file may ship sibling variants `templates/<family>/<file>.<level>`.
- The engine resolves the source as: **use `<file>.<level>` if it exists, else
  fall back to the base `<file>` (which *is* `standard`).**
- Therefore only the ~5 sensitive files need `.light` / `.strict` variants; the
  manifest barely changes and every other file is automatically level-agnostic.
- `bootstrap apply --level light|standard|strict` (default `standard`).
- The chosen level is recorded in `.bootstrap.yaml` (`level: standard`).
- **Detection never infers a level** (there is no reliable signal). It is always
  explicit, defaulting to `standard`.

## Interaction with the rest of the system

- **`doctor` / `reconcile`** read `level` from state and resolve the base template
  through the same `<file>.<level>` rule, so drift and 3-way merge keep working
  unchanged. The reconcile merge base (template at the recorded commit) must be
  resolved **at the recorded level** too.
- **Changing level later** (`apply --level strict` on a `standard` project) is a
  "level migration": the sensitive files become collisions → backup + replace (or
  `reconcile` to merge). Treat exactly like any other re-apply.
- **Profiles unchanged.** Inheritance still resolves files; the level only swaps
  the source of sensitive files at deposit time.
- **The auto PHPStan baseline already softens** the main "level 9 is scary" pain
  on existing projects, so `light` is mostly for *new/prototype* repos.

## Testing & docs impact

- bats: a small matrix: for each level, assert the sensitive files resolve to the
  right variant; assert `standard` output is unchanged (golden test).
- `validation/`: 2-3 cases (`apply --level light/strict`, doctor on a levelled
  project, level migration).
- README: one short subsection under "What's included"; a `--level` line in the
  `apply` command reference; mention `level` in `.bootstrap.yaml`.

## Non-goals

- No content-templating engine: levels are **file variants**, not parameterized
  files. If a file needs more than ~3 variants, it is the wrong tool.
- No more than three levels. No per-tool fine-grained sliders.
- No automatic level detection.

## Risks / open questions

- **Philosophy dilution.** bootstrap's value is "one baseline, no bikeshedding".
  Three levels reintroduce a small "which level?" choice. Mitigation: keep it to
  three, keep `standard` the loud default, document when to pick `light`/`strict`.
- **Locked params.** `strict`/`light` touch decisions the spec locked (PHPStan 9,
  Rector all-sets). Adopting this proposal means explicitly re-opening those for
  the non-default levels only.
- **Variant drift.** Three variants of five files = fifteen files to keep coherent
  as tools evolve. The golden `standard` test helps; `light`/`strict` need care.
- **Level migration UX.** Is downgrading `strict → light` expected to *remove*
  strict-only additions (e.g. `phpstan-strict-rules`)? Needs a defined rule.

## Recommendation

Defer. Implement **only if** real usage shows projects routinely wanting a cran
lighter or stricter. If/when it lands: three levels, `standard` default and
unchanged, `--level` flag, `<file>.<level>` variant resolution, ~5 sensitive
files, and re-open the locked params for the non-default levels only.
