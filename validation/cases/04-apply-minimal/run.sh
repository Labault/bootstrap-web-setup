#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib.sh"
p=$(new_project)
run "apply minimal" "$BS" apply --profile minimal --target "$p" --skip-bin-check
check "consignes partagées déposées" "$(exists "$p/AGENTS.md")"
check "Claude importe les consignes" "$(file_has "$p/CLAUDE.md" '^@AGENTS.md$')"
check ".editorconfig déposé" "$(exists "$p/.editorconfig")"
check ".bootstrap.yaml écrit" "$(exists "$p/.bootstrap.yaml")"
check "état enregistre le profil" "$(file_has "$p/.bootstrap.yaml" 'profile: minimal')"
check "exit 0" "$(exit_is 0)"
verdict
