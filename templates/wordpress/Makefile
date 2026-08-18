# Managed by bootstrap (wordpress profile). Standard quality targets.
# PHP tools come from the project through Composer.
.DEFAULT_GOAL := help

# Project-local targets belong in this optional, unmanaged file.
-include Makefile.local

.PHONY: help qa lint fix hooks cs cs-fix stan test

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

qa: lint test ## Run all configured quality checks

lint: ## Run every pre-commit hook on all files
	pre-commit run --all-files

fix: cs-fix ## Apply automatic fixes
	pre-commit run --all-files || true

hooks: ## Install git hooks (pre-commit + commit-msg)
	pre-commit install
	pre-commit install --hook-type commit-msg

cs: ## Check WordPress coding standards
	vendor/bin/phpcs

cs-fix: ## Fix auto-fixable WordPress coding-standard violations
	vendor/bin/phpcbf

stan: ## Run PHPStan at level 9
	vendor/bin/phpstan analyse --configuration=phpstan.dist.neon --memory-limit=512M --no-progress

test: ## Run PHPUnit when the project has a test suite
	@if [ -x vendor/bin/phpunit ]; then \
		vendor/bin/phpunit; \
	else \
		echo "No PHPUnit suite configured; skipping tests."; \
	fi
