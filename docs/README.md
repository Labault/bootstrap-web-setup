# Documentation

- [Architecture](architecture.md): CLI modules, manifests and profile inheritance.
- Profiles: [minimal](profiles/minimal.md), [Symfony](profiles/symfony.md),
  [WordPress](profiles/wordpress.md), [shell](profiles/shell.md),
  [fullstack](profiles/fullstack.md).
- [Validation](../validation/README.md): isolated acceptance tests and separate
  tool-installing smoke harnesses.
- [PHPStan policy](phpstan-policy.md): level 9 without automatic baselines,
  explicit legacy exceptions and adoption by existing projects.
- [Design specification](cahier-des-charges-bootstrap.md): original decisions;
  use the current profile documentation and code for implemented behavior.

`AGENTS.md` owns shared project guidance. Every profile deposits `CLAUDE.md`
as an import of that file. Edit the shared source and profile overrides, then
preview `bootstrap reconcile --dry-run` before updating an existing project.
