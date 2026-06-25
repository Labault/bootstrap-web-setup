# shellcheck shell=bash
# Reader for .bootstrap.yaml — the state file written by `apply` (see lib/state.sh).
# Used by `doctor` (Phase 2) to detect drift. Parsed with awk, no yq dependency,
# matching the exact shape we write.

# state_scalar <file> <key> -> value of a top-level scalar key (empty if absent)
state_scalar() {
  awk -v key="$2" '
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/[[:space:]]*#.*/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      print v; exit
    }
  ' "$1"
}

state_profile()    { state_scalar "$1" profile; }
state_version()    { state_scalar "$1" bootstrap_version; }
state_applied_at() { state_scalar "$1" applied_at; }

# state_files <file> -> "path<TAB>sha256<TAB>strategy" per line.
# strategy defaults to "replace" when the entry omits it.
state_files() {
  awk '
    function clean(x) { sub(/[[:space:]]*#.*/, "", x); gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
    /^[^[:space:]#]/ { inblk = ($0 ~ /^files:/) }
    inblk && /^[[:space:]]*-[[:space:]]*path:/ {
      if (have) print path "\t" sha "\t" strat
      v = $0; sub(/.*path:[[:space:]]*/, "", v); path = clean(v); sha = ""; strat = "replace"; have = 1
    }
    inblk && /^[[:space:]]*sha256:/   { v = $0; sub(/.*sha256:[[:space:]]*/, "", v);   sha   = clean(v) }
    inblk && /^[[:space:]]*strategy:/ { v = $0; sub(/.*strategy:[[:space:]]*/, "", v); strat = clean(v) }
    END { if (have) print path "\t" sha "\t" strat }
  ' "$1"
}
