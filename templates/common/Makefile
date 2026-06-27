# Managed by bootstrap. Standard quality targets.
# The tools come from your machine (mac-setup) or the project, never from here.
.DEFAULT_GOAL := help

# Project-local targets: drop them in an (optional, unmanaged) Makefile.local.
# Bootstrap never touches that file, so your custom targets survive re-apply.
-include Makefile.local

.PHONY: help qa lint fix hooks

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

qa: lint ## Run all quality checks

lint: ## Run every pre-commit hook on all files
	pre-commit run --all-files

fix: ## Re-run hooks, applying any auto-fixes
	pre-commit run --all-files || true

hooks: ## Install git hooks (pre-commit + commit-msg)
	pre-commit install
	pre-commit install --hook-type commit-msg
