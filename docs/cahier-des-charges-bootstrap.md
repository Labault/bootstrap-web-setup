# Cahier des charges — `bootstrap`

> Nom de travail. À brander plus tard (format court type `WebKit`, `Forge`, etc.).
> Projet compagnon de **mac-setup**, opérant au niveau projet et non au niveau machine.

---

## 1. Contexte et raison d'être

`mac-setup` outille la **machine** : il installe les binaires (Homebrew, CLI, runtimes) et pose la config **globale** dans `~/`. Une fois par Mac.

Il manque le maillon suivant : quand on démarre — ou qu'on reprend — un projet web, il faut redéposer à chaque fois la même couche qualité / CI / sécurité (`.pre-commit-config.yaml`, `phpstan.neon`, workflows GitHub Actions…). Aujourd'hui c'est du copier-coller manuel d'un projet à l'autre, avec la dérive habituelle : versions qui divergent, fichiers oubliés, configs incohérentes.

`bootstrap` automatise ce dépôt. Il prend un dossier de projet et y installe une configuration de qualité standardisée, reproductible et versionnée.

**Principe directeur, non négociable :** `bootstrap` **n'installe aucun binaire**. Il dépose uniquement des fichiers de config. Les outils qui lisent ces fichiers sont fournis par `mac-setup`. La config sans l'outil est un fichier mort — d'où une dépendance explicite décrite en §9.

---

## 2. Cible

- **Utilisateur :** mono-utilisateur au départ (toi), forkable ensuite.
- **Projets visés :** projets web, principalement PHP/Symfony, éventuellement avec une couche front JS/TS.
- **État du projet :** indifférent. Doit fonctionner sur un projet **neuf** (dossier quasi vide) comme sur un projet **existant** (déjà du code, déjà des fichiers).
- **Plateforme :** macOS (cohérent avec `mac-setup`), mais le script ne doit rien faire de macOS-spécifique — il manipule des fichiers, donc reste portable Linux/CI par effet de bord.

---

## 3. Cohérence avec mac-setup

`bootstrap` réutilise les patterns déjà éprouvés dans `mac-setup`, pour que les deux outils se ressemblent et que la courbe d'apprentissage soit nulle :

| Pattern mac-setup | Repris dans bootstrap |
| --- | --- |
| Profils (`minimal`, `full`) pilotés par fichier | Profils `minimal` / `symfony` / `fullstack` |
| `--dry-run` (preview sans rien changer) | Idem, obligatoire |
| `mac doctor` (état machine vs attendu) | `bootstrap doctor` (binaires requis + dérive de config) |
| Backup avant remplacement d'un fichier existant | Idem, indispensable sur projet existant |
| Idempotence (rerun sans casse) | Idem |
| Config data-driven (Brewfiles par profil) | Manifeste par profil (voir §7) |

---

## 4. Modèle de cycle de vie — one-shot évolutif

La question « outil one-shot ou outil durable » ne se joue pas sur le nombre de fois où on lance la commande. Elle se joue sur **une seule chose : est-ce que `bootstrap` garde la mémoire des projets qu'il a touchés et assume la responsabilité de les faire évoluer ?**

- **One-shot (scaffold)** : il pose les fichiers et oublie. Le projet devient propriétaire de sa config dès la seconde d'après. Mental model : `composer create-project`.
- **Durable (managed)** : `bootstrap` reste la source de vérité, les projets sont des consommateurs qu'il peut resynchroniser. Mental model : `mac-setup` lui-même (`mac update`, `mac doctor`).

### 4.1 Décision

**One-shot par défaut, conçu dès le départ pour devenir durable.** On ne construit **pas** de moteur de merge en v1 — c'est le composant le plus cher et le moins urgent. Mais on dépose immédiatement la pièce qui rend le durable possible plus tard, à coût quasi nul.

Justification : le coût d'un outil durable n'est pas dans « se souvenir des projets » (tracer est gratuit), il est dans « réconcilier les modifications locales » (le 3-way merge, cher et bugogène — des outils entiers comme `cruft` ou Yeoman n'existent que pour ça). On capte donc ~90 % du bénéfice du durable en payant ~10 % du coût.

Réversibilité : ajouter du durable par-dessus du one-shot est facile ; retirer le couplage d'un outil trop managé est pénible. Le sens du phasage va donc dans le bon sens.

### 4.2 La pièce clé — `.bootstrap.yaml`

À chaque `apply`, `bootstrap` dépose dans le projet un fichier d'état décrivant ce qu'il a fait : profil utilisé, version des templates, liste des fichiers déposés. Ça ne change rien au comportement v1, ça coûte quelques lignes à écrire, et c'est ce qui débloque toute la suite. Contrat de contenu en §10.

### 4.3 Phasage

| Phase | Quand | Ce que ça fait |
| --- | --- | --- |
| **Phase 1 — one-shot tracké** | v1, maintenant | `apply` dépose la config **et** écrit `.bootstrap.yaml`. Aucune réconciliation. `bootstrap update` ne met à jour que `bootstrap` lui-même, **jamais** les projets. |
| **Phase 2 — détection de dérive** | si le besoin se confirme | `bootstrap doctor` lit `.bootstrap.yaml`, le compare à la version courante des templates et **signale** la dérive (« projet X en retard de 2 versions sur le template CI »). Il ne merge pas : il propose de réappliquer manuellement, avec backup. Mode **tracké mais pas auto-mergé**. |
| **Phase 3 — réconciliation** | optionnel, lointain | vrai merge à trois voies (version d'origine / version locale / nouveau template), façon `cruft`. N'est construit que si le besoin est réellement prouvé. |

En clair : la v1 reste simple et démontrable tout de suite, mais le `.bootstrap.yaml` garde la porte ouverte au tempérament de mainteneur sans payer le coût du merge avant de l'avoir voulu.

---

## 5. Périmètre

L'inventaire complet de `mac-setup` se range en trois familles. **Seule la famille 2 entre dans `bootstrap`.** Les deux autres sont documentées ici pour traçabilité.

### 5.1 Famille 2 — config projet → **DANS le périmètre**

Outils dont le binaire vit sur la machine mais dont le fichier de config décrit *comment l'appliquer à ce projet*. C'est exactement ce que `bootstrap` dépose.

### 5.2 Famille 1 — outils machine → **HORS périmètre**

Confort terminal et applications GUI. Aucune empreinte projet, leur config (si elle existe) vit dans `~/`.

> `antidote`, `autojump`, `bat`, `duf`, `dust`, `glances`, `lsd`, `terminal-notifier`, `tldr`, `tokei`, `tree`, `gh`, `git-delta`, `KeeWeb`, `symfony-cli`, `act`, `ctop`, `OrbStack`, Sublime Text, Warp, Beekeeper Studio, CleanShot X, GIMP, Ice, Notion, Obsidian, Pearcleaner, Raycast, Stats, SwiftBar, Bruno, Excalidraw, Firefox, Chrome, RealFaviconGenerator, remove.bg, Codex, CodexBar, Ollama, Sentry (desktop/SDK).

### 5.3 Famille 3 — runtimes & manifests → **HORS périmètre**

Le projet possède bien des fichiers associés, mais ce sont des **manifests de dépendances** gérés par le projet lui-même, pas des configs déposées par `bootstrap`.

> `php`, `node`, `composer` → `composer.json`, `package.json`
> `Pest` / `phpunit`, `pcov`, `xdebug` → arrivent via `composer require`, configurés dans le manifest du projet.

`bootstrap` ne touche jamais à `composer.json` ni `package.json`. Il peut au mieux **suggérer** des `require-dev` à ajouter (voir §10), sans les écrire.

---

## 6. Inventaire détaillé — outils repris (famille 2)

Pour chaque outil : le fichier déposé, son rôle, et le profil minimal qui le déclenche.

| # | Outil | Fichier(s) déposé(s) | Rôle | Profil |
| --- | --- | --- | --- | --- |
| 1 | **pre-commit** | `.pre-commit-config.yaml` | Orchestrateur : lance tous les hooks ci-dessous avant chaque commit | `minimal` |
| 2 | **EditorConfig** | `.editorconfig` | Indentation / fins de ligne / charset homogènes, tous éditeurs | `minimal` |
| 3 | **editorconfig-checker** | (hook pre-commit) | Vérifie que le repo respecte `.editorconfig` | `minimal` |
| 4 | **commit-msg lint** | `scripts/lint-commit-msg.sh` | Valide le format des messages (gitmoji + Conventional Commits), script shell autonome | `minimal` |
| 5 | **gitleaks** | `.gitleaks.toml` + workflow | Scan des secrets commités, en local et en CI | `minimal` |
| 6 | **shellcheck** | `.shellcheckrc` | Lint des scripts shell | `minimal` |
| 7 | **markdownlint-cli2** | `.markdownlint-cli2.yaml` | Formatage Markdown cohérent | `minimal` |
| 8 | **actionlint** | (hook) + `.github/actionlint.yaml` *(optionnel)* | Valide les workflows GitHub Actions | `minimal` |
| 9 | **lychee** | `lychee.toml` + workflow | Détecte les liens morts dans la doc | `minimal` |
| 10 | **hadolint** | `.hadolint.yaml` | Lint des Dockerfile | `minimal` (si Docker) |
| 11 | **PHPStan** | `phpstan.dist.neon` | Analyse statique PHP | `symfony` |
| 12 | **PHP-CS-Fixer** | `.php-cs-fixer.dist.php` | Autoformat du code PHP | `symfony` |
| 13 | **Rector** | `rector.php` | Refacto automatique / montée de version PHP | `symfony` |
| 14 | **ESLint** | `eslint.config.js` | Lint JS/TS | `fullstack` |
| 15 | **Prettier** | `.prettierrc` + `.prettierignore` | Formatage front | `fullstack` |
| 16 | **Husky + lint-staged** | `.husky/` + clé `lint-staged` | Hooks front (uniquement si front présent) | `fullstack` |

> Note Husky : volontairement réservé au profil `fullstack`. Sur un projet PHP pur, tout passe par `pre-commit` (déjà installé via mac-setup, agnostique du langage). On ne tire Node + Husky que là où il y a déjà du Node de toute façon.

### Fichiers transverses déposés (pas un outil, mais du périmètre)

| Fichier | Rôle | Profil |
| --- | --- | --- |
| `.github/workflows/ci.yml` | Pipeline qualité : install, analyse statique, CS, tests | `minimal`+ |
| `.github/workflows/security.yml` | gitleaks + dependency review | `minimal`+ |
| `.github/dependabot.yml` *(ou `renovate.json`)* | Mises à jour de dépendances | `minimal`+ |
| `.github/ISSUE_TEMPLATE/` | Gabarits d'issues | `minimal`+ |
| `.github/PULL_REQUEST_TEMPLATE.md` | Gabarit de PR | `minimal`+ |
| `Makefile` | Cibles standard (`make lint`, `make test`, `make qa`…) | `minimal`+ |
| `SECURITY.md` | Politique de sécurité | `minimal`+ |
| `CONTRIBUTING.md` | Conventions de contribution | `minimal`+ |
| `.gitignore` | Base + fragments par stack | `minimal`+ |
| `.vscode/extensions.json` | Extensions recommandées au niveau projet | `minimal`+ |
| `CLAUDE.md` | Contexte projet pour Claude Code (cohérent avec ton workflow) | `minimal`+ |
| `.bootstrap.yaml` | État du dépôt (profil, version, fichiers) — voir §4.2 et §10 | `minimal`+ |

> Choix Dependabot vs Renovate : Dependabot est natif GitHub, zéro setup → bon défaut. Renovate est plus puissant et self-hostable (cohérent avec ton profil) → option du profil avancé. À trancher en §11.

---

## 7. Profils

Le profil décide **quels fichiers sont déposés** et **quels binaires sont requis**. Comme dans `mac-setup`, ils sont data-driven : un manifeste par profil, pas du code en dur.

| Profil | Pour quoi | Contenu |
| --- | --- | --- |
| `minimal` | N'importe quel repo web, agnostique langage | pre-commit, editorconfig, commit-msg lint, gitleaks, shellcheck, markdownlint, actionlint, lychee, workflows de base, fichiers transverses |
| `symfony` | Projet PHP/Symfony | `minimal` + PHPStan, PHP-CS-Fixer, Rector, hadolint, cibles `make` PHP, étapes CI PHP |
| `fullstack` | Symfony + front JS/TS | `symfony` + ESLint, Prettier, Husky + lint-staged, étapes CI front |

### Format du manifeste (proposition)

Un fichier déclaratif par profil, lu par le script. Exemple conceptuel :

```yaml
# profiles/symfony.yaml
extends: minimal          # héritage de profil
requires_bin:             # binaires que mac-setup doit avoir installés
  - php
  - composer
  - phpstan
  - php-cs-fixer
  - rector
files:                    # source → destination dans le projet
  - src: templates/phpstan.dist.neon
    dest: phpstan.dist.neon
  - src: templates/.php-cs-fixer.dist.php
    dest: .php-cs-fixer.dist.php
  - src: templates/rector.php
    dest: rector.php
```

L'héritage (`extends`) évite la duplication : `symfony` = `minimal` + ses ajouts, `fullstack` = `symfony` + ses ajouts.

---

## 8. Structure skeleton — arborescence cible

Arborescence du **dépôt `bootstrap`** lui-même (les templates qu'il distribue) :

```text
bootstrap/
├── install.sh                  # point d'entrée, façon mac-setup
├── bin/
│   └── bootstrap               # CLI principale
├── profiles/
│   ├── minimal.yaml            # manifeste profil minimal
│   ├── symfony.yaml            # manifeste profil symfony
│   └── fullstack.yaml          # manifeste profil fullstack
├── templates/                  # tous les fichiers déposables
│   ├── common/
│   │   ├── .editorconfig
│   │   ├── .gitignore
│   │   ├── .pre-commit-config.yaml
│   │   ├── scripts/lint-commit-msg.sh
│   │   ├── .gitleaks.toml
│   │   ├── .shellcheckrc
│   │   ├── .markdownlint-cli2.yaml
│   │   ├── lychee.toml
│   │   ├── Makefile
│   │   ├── SECURITY.md
│   │   ├── CONTRIBUTING.md
│   │   ├── CLAUDE.md
│   │   ├── .vscode/
│   │   │   └── extensions.json
│   │   └── .github/
│   │       ├── workflows/
│   │       │   ├── ci.yml
│   │       │   └── security.yml
│   │       ├── dependabot.yml
│   │       ├── PULL_REQUEST_TEMPLATE.md
│   │       └── ISSUE_TEMPLATE/
│   │           ├── bug_report.md
│   │           └── feature_request.md
│   ├── symfony/
│   │   ├── phpstan.dist.neon
│   │   ├── .php-cs-fixer.dist.php
│   │   ├── rector.php
│   │   └── .hadolint.yaml
│   └── fullstack/
│       ├── eslint.config.js
│       ├── .prettierrc
│       ├── .prettierignore
│       └── .husky/
│           ├── pre-commit
│           └── commit-msg
├── docs/
└── README.md
```

Et voici ce qui **atterrit dans un projet cible** après `bootstrap apply --profile symfony` :

```text
mon-projet/
├── .bootstrap.yaml             # état du dépôt (profil + version + fichiers)
├── .editorconfig
├── .gitignore                  # fusionné si déjà présent (voir §9)
├── .gitleaks.toml
├── .shellcheckrc
├── .markdownlint-cli2.yaml
├── .pre-commit-config.yaml
├── scripts/lint-commit-msg.sh
├── lychee.toml
├── phpstan.dist.neon
├── .php-cs-fixer.dist.php
├── rector.php
├── .hadolint.yaml
├── Makefile
├── SECURITY.md
├── CONTRIBUTING.md
├── CLAUDE.md
├── .vscode/
│   └── extensions.json
└── .github/
    ├── workflows/
    │   ├── ci.yml
    │   └── security.yml
    ├── dependabot.yml
    ├── PULL_REQUEST_TEMPLATE.md
    └── ISSUE_TEMPLATE/
        ├── bug_report.md
        └── feature_request.md
```

---

## 9. Comportement du script

### 9.1 Commandes

| Commande | Effet |
| --- | --- |
| `bootstrap apply --profile <p>` | Dépose la config du profil dans le dossier courant + écrit `.bootstrap.yaml` |
| `bootstrap apply --dry-run` | Liste ce qui serait écrit / fusionné / sauvegardé, ne change rien |
| `bootstrap doctor` | Vérifie binaires requis + (Phase 2) signale la dérive de config |
| `bootstrap update` | Met à jour `bootstrap` lui-même (façon `mac update`). **Ne touche pas aux projets.** |
| `bootstrap list` | Liste les profils disponibles et leur contenu |

### 9.2 Étape 0 — vérification des binaires (bloquant)

Avant tout dépôt, le script lit `requires_bin` du profil et vérifie que chaque binaire est présent (`command -v`). Si un outil manque :

- en mode normal : **avertir** et proposer la commande `brew install` correspondante ;
- proposer `--skip-bin-check` pour forcer (cas CI, ou installation différée).

C'est la garantie qu'on ne se retrouve pas avec des `.neon` et `.yaml` inertes et un hook pre-commit qui pète au premier commit.

### 9.3 Détection neuf vs existant — gestion des collisions

Pour chaque fichier à déposer, trois cas :

1. **Absent** → écriture simple.
2. **Présent, identique au template** → no-op (idempotence).
3. **Présent, différent** → selon le type :
   - fichiers « fusionnables » (`.gitignore`, `.vscode/extensions.json`) → **fusion** intelligente (union des lignes, dédup) ;
   - fichiers de config « possédés par bootstrap » → **backup puis remplacement**, avec un drapeau `--no-overwrite` pour ne jamais écraser.

### 9.4 Écriture de `.bootstrap.yaml`

En fin de `apply`, le script écrit (ou met à jour) `.bootstrap.yaml` à la racine du projet : profil appliqué, version des templates, horodatage, et la liste des fichiers effectivement déposés. C'est l'unique trace qui rendra la Phase 2 possible. Conforme au modèle de cycle de vie du §4.

### 9.5 Backup

Tout fichier écrasé est sauvegardé avant, façon `mac-setup` :
`~/Documents/Backups/bootstrap/<nom-projet>/<timestamp>/`. Rollback manuel toujours possible.

### 9.6 Idempotence

Relancer `bootstrap apply` sur un projet déjà configuré ne doit produire aucun changement si rien n'a bougé côté templates. Un rerun = mise à jour propre, pas une duplication.

### 9.7 Installation des hooks

Après dépôt du profil, le script lance `pre-commit install` (et `pre-commit install --hook-type commit-msg`) pour le linter de message shell) pour activer les hooks. Sur `fullstack`, équivalent côté Husky.

---

## 10. Contrat de contenu des fichiers clés

Le script copie des templates, mais ces templates ont un contrat minimal à respecter.

- **`.pre-commit-config.yaml`** — doit câbler : editorconfig-checker, gitleaks, shellcheck, markdownlint-cli2, actionlint, hadolint, le linter commit-msg shell (`scripts/lint-commit-msg.sh`). En profil `symfony`, ajouter PHPStan / PHP-CS-Fixer / Rector via hooks `local` appelant les binaires du projet ou de la machine.
- **`ci.yml`** — déclencheurs `push` + `pull_request`. Étapes : checkout, setup PHP **8.4**, `composer install`, `php-cs-fixer --dry-run --diff` (ruleset `@Symfony`), `phpstan analyse` (niveau 9), `rector --dry-run`, tests (Pest/PHPUnit). Échec bloquant.
- **`security.yml`** — gitleaks sur l'historique + `dependency-review-action` sur les PR.
- **`Makefile`** — cibles a minima : `make qa` (= lint + stan + test), `make lint`, `make stan`, `make cs`, `make test`, `make fix` (auto-correction CS + Rector).
- **`scripts/lint-commit-msg.sh`** — script shell autonome validant gitmoji + Conventional Commits (aligné sur `mac-setup`).
- **`CLAUDE.md`** — squelette : stack, conventions de commit, commandes `make`, règles projet. À enrichir par projet.
- **`.bootstrap.yaml`** — champs minimaux : `profile` (profil appliqué), `bootstrap_version` (version des templates au moment du dépôt), `applied_at` (horodatage ISO), `files` (liste des fichiers déposés, idéalement avec un hash par fichier pour la détection de dérive en Phase 2). Fichier lu par `bootstrap doctor`, jamais édité à la main.

> Pour les `require-dev` PHP (phpstan/extension, php-cs-fixer, rector, pest), `bootstrap` ne modifie pas `composer.json`. Il **affiche** en fin de run la ligne `composer require --dev …` à exécuter si les paquets manquent.

---

## 11. Contraintes et décisions techniques

1. **`pre-commit` est le socle unique** au niveau `minimal`/`symfony`. Husky n'apparaît qu'en `fullstack`. Pas deux gestionnaires de hooks en doublon (la redondance à nettoyer dans mac-setup sert de leçon).
2. **Agnostique langage au niveau `minimal`** : le profil de base ne présuppose ni PHP ni Node.
3. **Le script écrit, n'installe pas.** Toute installation de binaire est hors scope, par conception.
4. **Aucune écriture dans les manifests** (`composer.json`, `package.json`) : suggestion uniquement.
5. **Langage du script :** Bash, pour rester cohérent avec `mac-setup` et sans dépendance d'exécution. Manifests en YAML lus via `yq` (à ajouter aux `requires_bin` du bootstrap lui-même).
6. **Modèle de cycle de vie : tranché.** One-shot évolutif, voir §4. Pas de moteur de merge en v1 ; `.bootstrap.yaml` déposé dès la v1 pour ouvrir la Phase 2.
7. **Paramètres applicatifs verrouillés :**
   - Détection auto du profil : `composer.json` → `symfony`, `+ package.json` → `fullstack`, override par `--profile`.
   - PHP **8.4** seul en CI (pas de matrice).
   - PHPStan **niveau 9**, avec **baseline auto** générée quand le projet n'est pas vierge.
   - PHP-CS-Fixer : ruleset **`@Symfony`**.
   - Rector : **tous les sets** activés (dry-run en CI, fix manuel via `make rector-fix`).
   - Hooks pre-commit en mode **`local`** (appellent les binaires machine/projet, pas de repos pinnés).
   - Mises à jour de dépendances : **Dependabot** (`.github/dependabot.yml`).
   - Fusion `.gitignore` par **sections balisées** (`# >>> bootstrap` … `# <<< bootstrap`).
   - Versioning **global** du bootstrap, écrit dans `.bootstrap.yaml` (un seul numéro en v1).
8. **Reporté — non bloquant pour la v1 :**
   - `bootstrap` distribué aussi comme **repo template GitHub** (cas « projet neuf » pur) — à décider une fois le script debout.
   - Format du hash dans `.bootstrap.yaml` (par fichier vs global) — repoussé à la Phase 2.

---

## 12. Définition de « terminé » (DoD)

### v1 — one-shot tracké (Phase 1)

- [ ] `install.sh` met en place la CLI `bootstrap`, façon `mac-setup`.
- [ ] Trois profils fonctionnels (`minimal`, `symfony`, `fullstack`) avec héritage.
- [ ] `bootstrap doctor` détecte les binaires manquants et propose la commande d'install.
- [ ] `bootstrap apply` est idempotent, gère neuf + existant, fusionne `.gitignore`/`extensions.json`, backup avant écrasement.
- [ ] `apply` écrit `.bootstrap.yaml` (profil + version + fichiers).
- [ ] `bootstrap update` met à jour le bootstrap lui-même sans toucher aux projets.
- [ ] `--dry-run` sur toutes les commandes mutantes.
- [ ] Hooks `pre-commit` (+ `commit-msg`) installés et fonctionnels après `apply`.
- [ ] Le pipeline CI déposé tourne vert sur un projet Symfony de référence.
- [ ] Documentation : README + une page par profil.
- [ ] Le repo `bootstrap` se respecte lui-même (il s'auto-applique le profil `minimal`).

### Plus tard — détection de dérive (Phase 2, hors v1)

- [ ] `bootstrap doctor` lit `.bootstrap.yaml` et signale les projets en retard de version.
- [ ] Proposition de réapplication manuelle avec backup, sans merge automatique.

---

*Document de conception — v1.0. Toutes les décisions structurantes verrouillées (§11.7) ; ne restent que les points reportés du §11.8, non bloquants pour la v1.*
