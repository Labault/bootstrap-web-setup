# AGENTS.md

Shared conventions for this project, read by Claude Code (via `CLAUDE.md`'s
`@AGENTS.md` import), Codex and other AI tools. Committed, so every collaborator
gets the same rules.

## Code style

Conventions to apply by hand. Yoda conditions are already enforced by
php-cs-fixer (`@Symfony`); the rest are not linter-checked, so stay disciplined.

### Yoda conditions

Equality/identity against a literal, `null` or a constant: put the non-variable
operand on the left. Applies to `==`, `===`, `!=`, `!==` only (not `<`, `>`,
`<=`, `>=`, nor comparisons between two variables/expressions).

```php
// Good
if (null === $user) { ... }
if ('' !== $search) { ... }
if (0 === $count) { ... }
if (Status::Active === $order->getStatus()) { ... }

// Bad
if ($user === null) { ... }
if ($search !== '') { ... }
```

### Early returns

Leave a function as soon as possible (`return`, `throw`, `continue`, `break`):
errors, guards and early exits first. No `else` after a `return`/`throw`. Keep
`if` nesting shallow.

```php
// Good — early returns, no needless else
public function update(Entry $entry, ?User $user): Response
{
    if (null === $user) {
        throw $this->createAccessDeniedException();
    }

    if ($entry->getOwner() !== $user) {
        throw $this->createNotFoundException();
    }

    return $this->render('entry/edit.html.twig', ['entry' => $entry]);
}
```

### Unused variables

No local variable that is assigned but never read. If a value is only used for
its side effect, call the expression directly. These stay "used" (false
positives): interpolated (`"$x"`, heredoc), passed by reference (`&$item`),
captured by `use ($x)` in a closure, or inside `compact()`/`extract()`. When in
doubt, keep the variable. Never touch function parameters (public signature).

```php
// Good — direct call, no useless intermediate
$this->em->flush();

// Bad — $result is never read again
$result = $this->em->flush();
```

### Alphabetical ordering

Sort ascending, case-insensitive: class methods, class constants, enum cases,
keys of a multi-line associative array, and `match` arms. Keep the existing
order where it carries meaning:

- constructor parameters (dependency / logical grouping);
- short arrays whose position is semantic (coordinates, an ordered tuple);
- business-logic order (`match` with a `default`, workflow transitions,
  algorithm steps);
- entity members: getters mirror the constructor/property order (fields that
  belong together stay together), mutations and derived values come after.

```php
// Good — alphabetical enum cases (and matching label arms)
enum Status: string
{
    case Active = 'active';
    case Archived = 'archived';
    case Draft = 'draft';
    case Pending = 'pending';
}
```

### Typographic apostrophes

In user-visible PHP strings (flash messages, labels, descriptions, error
messages), use the typographic apostrophe `’` (U+2019) instead of the straight
`'` (replace escaped `\'` too where possible). Bonus: `’` is not a string
delimiter, so it never breaks a single-quoted
string, `'L’identifiant n’existe pas.'` is valid. Use double quotes only when
the string interpolates a variable (`"{$name} a été enregistré."`).

Does not apply to: slugs, technical keys, route names, service ids, SQL/DQL,
enum values, annotations/attributes.

```php
// Good
$this->addFlash('success', 'Élément créé avec succès.');
throw new \RuntimeException('L’identifiant n’existe pas.');

// Bad
$this->addFlash('success', "Élément créé avec succès.");
```
