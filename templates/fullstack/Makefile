# Managed by bootstrap (fullstack profile). Standard quality targets.
# Tools come from the project (vendor/bin, node_modules/.bin) or your machine,
# never from here.
.DEFAULT_GOAL := help

.PHONY: help qa lint fix hooks cs cs-fix stan rector rector-fix test front front-fix

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

qa: lint stan test ## Run all quality checks (lint + stan + test)

lint: ## Run every pre-commit hook and the front linters on all files
	pre-commit run --all-files
	$(MAKE) front

cs: ## Check coding style (PHP-CS-Fixer, dry-run)
	PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer fix --dry-run --diff

cs-fix: ## Fix coding style (PHP-CS-Fixer)
	PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer fix

stan: ## Static analysis (PHPStan)
	vendor/bin/phpstan analyse --no-progress

rector: ## Show refactorings (Rector, dry-run)
	vendor/bin/rector process --dry-run

rector-fix: ## Apply refactorings (Rector)
	vendor/bin/rector process

test: ## Run the test suite (Pest or PHPUnit)
	@if [ -f vendor/bin/pest ]; then vendor/bin/pest; else vendor/bin/phpunit; fi

front: ## Lint the front (ESLint + Prettier check + type-check)
	npx --no-install eslint .
	npx --no-install prettier --check .
	@if git ls-files '*.ts' '*.tsx' | grep -q .; then \
		npx --no-install tsc --noEmit; \
	else \
		echo "No TypeScript sources found, skipping type-check."; \
	fi

front-fix: ## Auto-fix the front (ESLint --fix + Prettier --write)
	npx --no-install eslint --fix .
	npx --no-install prettier --write .

fix: cs-fix rector-fix front-fix ## Auto-fix coding style, refactorings and front

# Husky is the single git-hook owner here (it sets core.hooksPath), so we do NOT
# run `pre-commit install`: pre-commit refuses to install when core.hooksPath is
# set. The deposited .husky/pre-commit delegates to `pre-commit run` (§11.1).
hooks: ## Install git hooks (Husky; delegates to pre-commit)
	npx --no-install husky
