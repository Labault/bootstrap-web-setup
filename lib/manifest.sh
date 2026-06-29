# shellcheck shell=bash
# Manifest parser and profile-inheritance resolution.
#
# We deliberately do NOT depend on yq: the manifest format is a small, fixed
# subset of YAML that we control, so a focused awk parser is enough and keeps
# bootstrap dependency-free. Supported shape (2-space indent):
#
#   extends: <parent>
#   requires_bin:
#     - <bin>
#   files:
#     - src: <path>
#       dest: <path>
#       strategy: replace | merge-gitignore | merge-json   # optional
#
# Comments (# ...) and blank lines are ignored.

manifest_path() {
  printf '%s/profiles/%s.yaml' "$BOOTSTRAP_ROOT" "$1"
}

# manifest_extends <file> -> prints the parent profile name (empty if none)
manifest_extends() {
  awk '
    /^extends:/ {
      v = $0; sub(/^extends:[[:space:]]*/, "", v); sub(/[[:space:]]*#.*/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit
    }
  ' "$1"
}

# manifest_seq <file> <key> -> one item per line for the sequence under <key>
# (this profile only). Strips inline comments and surrounding quotes.
manifest_seq() {
  awk -v key="$2" '
    /^[^[:space:]#]/ { inblk = ($0 ~ ("^" key ":")) }
    inblk && /^[[:space:]]+-[[:space:]]/ {
      v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v); sub(/[[:space:]]*#.*/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/^"|"$/, "", v)
      if (v != "") print v
    }
  ' "$1"
}

# manifest_requires_bin <file> -> one binary per line (this profile only)
manifest_requires_bin() {
  manifest_seq "$1" requires_bin
}

# manifest_files <file> -> "src<TAB>dest<TAB>strategy" per line (this profile only)
manifest_files() {
  awk '
    function clean(x) { sub(/[[:space:]]*#.*/, "", x); gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
    /^[^[:space:]#]/ { inblk = ($0 ~ /^files:/) }
    inblk && /^[[:space:]]*-[[:space:]]*src:/ {
      if (have) print src "\t" dest "\t" strat
      v = $0; sub(/.*src:[[:space:]]*/, "", v); src = clean(v); dest = ""; strat = "replace"; have = 1
    }
    inblk && /^[[:space:]]*dest:/  { v = $0; sub(/.*dest:[[:space:]]*/, "", v);     dest  = clean(v) }
    inblk && /^[[:space:]]*strategy:/ { v = $0; sub(/.*strategy:[[:space:]]*/, "", v); strat = clean(v) }
    END { if (have) print src "\t" dest "\t" strat }
  ' "$1"
}

# resolve_chain <profile> -> profile names from root ancestor down to <profile>.
# Guards against cycles and unknown profiles.
resolve_chain() {
  local profile="$1" seen="${2:-}"
  local file
  file="$(manifest_path "$profile")"
  [[ -f "$file" ]] || die "Unknown profile: '$profile' (no $file)"
  case " $seen " in
  *" $profile "*) die "Cyclic profile inheritance detected at '$profile'" ;;
  esac
  local parent
  parent="$(manifest_extends "$file")"
  if [[ -n "$parent" ]]; then
    resolve_chain "$parent" "$seen $profile"
  fi
  printf '%s\n' "$profile"
}

# resolve_seq <profile> <key> -> deduped items for <key> across the whole
# inheritance chain, in first-seen order (parent before child).
resolve_seq() {
  local profile="$1" key="$2" p item
  local -a seen=()
  while IFS= read -r p; do
    while IFS= read -r item; do
      [[ -z "$item" ]] && continue
      local already=0 s
      for s in ${seen[@]+"${seen[@]}"}; do [[ "$s" == "$item" ]] && already=1 && break; done
      [[ "$already" == 1 ]] && continue
      seen+=("$item")
      printf '%s\n' "$item"
    done < <(manifest_seq "$(manifest_path "$p")" "$key")
  done < <(resolve_chain "$profile")
}

# resolve_requires_bin <profile> -> deduped binaries across the whole chain.
resolve_requires_bin() {
  resolve_seq "$1" requires_bin
}

# resolve_files <profile> -> "src<TAB>dest<TAB>strategy" across the whole chain.
# Child entries override parent entries that target the same dest (child wins),
# while preserving first-seen order of each dest.
resolve_files() {
  local p
  local -a order=()
  local -A line_for=()
  while IFS= read -r p; do
    while IFS=$'\t' read -r src dest strat; do
      [[ -z "$dest" ]] && continue
      if [[ -z "${line_for[$dest]+x}" ]]; then
        order+=("$dest")
      fi
      line_for[$dest]="$src"$'\t'"$dest"$'\t'"$strat"
    done < <(manifest_files "$(manifest_path "$p")")
  done < <(resolve_chain "$1")
  local d
  for d in ${order[@]+"${order[@]}"}; do
    printf '%s\n' "${line_for[$d]}"
  done
}
