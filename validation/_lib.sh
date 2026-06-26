#!/usr/bin/env bash
# Shared helpers for the validation cases. Each case/run.sh sources this.
# It gives every case an isolated workspace, captures output, evaluates a
# pass/fail criterion and writes RESULT.txt + output.log INTO the case folder.
set -uo pipefail


# Derive the repo from this file's own location (validation/_lib.sh -> repo root)
# so the harness is portable (CI, anywhere). Override with BOOTSTRAP_REPO if set.
REPO="${BOOTSTRAP_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC2034  # consumed by case run.sh scripts
BS="$REPO/bin/bootstrap"

# CASE_DIR = the folder of the run.sh that sourced us (where we leave log/result).
CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
# Work OUTSIDE the repo (a real temp dir): cases that test "non-git" directories
# must not be fooled by an enclosing git checkout when this harness lives in one.
RUN_TMP="$(mktemp -d)"
WORK="$RUN_TMP/work"
export BACKUP_BASE="$RUN_TMP/backups"
LOG="$CASE_DIR/output.log"
RESULT="$CASE_DIR/RESULT.txt"

rm -f "$LOG" "$RESULT"
mkdir -p "$WORK"

# new_project [name] -> path to a fresh git-initialised project dir.
new_project() {
  local p="$WORK/${1:-proj}"
  mkdir -p "$p"
  git -C "$p" init -q
  printf '%s\n' "$p"
}

# workcopy -> path to a copy of the repo WITH .git (needed for reconcile base).
# Echoes the copy's bin/bootstrap path.
workcopy() {
  local w="$WORK/repo"
  mkdir -p "$w"
  cp -R "$REPO/." "$w/"
  printf '%s/bin/bootstrap\n' "$w"
}

# run "<label>" cmd...  -> runs the command, appends to the log, remembers the
# exit code in LAST_RC and the combined output in LAST_OUT.
run() {
  local label="$1"; shift
  { printf '\n# %s\n$ %s\n' "$label" "$*"; } >>"$LOG"
  LAST_OUT="$("$@" 2>&1)"; LAST_RC=$?
  printf '%s\n[exit=%s]\n' "$LAST_OUT" "$LAST_RC" >>"$LOG"
}

# Assertions. Each records a line; the case passes only if ALL pass.
_FAILS=0
check() {                      # check "<description>" <0-or-1 truth>
  local desc="$1" ok="$2"
  if [[ "$ok" == 1 ]]; then printf '  [ok ] %s\n' "$desc" | tee -a "$LOG"
  else printf '  [FAIL] %s\n' "$desc" | tee -a "$LOG"; _FAILS=$((_FAILS+1)); fi
}
exit_is()      { [[ "$LAST_RC" == "$1" ]] && echo 1 || echo 0; }   # exact code
exit_nonzero() { [[ "$LAST_RC" -ne 0 ]] && echo 1 || echo 0; }
out_has()      { [[ "$LAST_OUT" == *"$1"* ]] && echo 1 || echo 0; }
out_hasnt()    { [[ "$LAST_OUT" != *"$1"* ]] && echo 1 || echo 0; }
file_has()     { grep -q -- "$2" "$1" 2>/dev/null && echo 1 || echo 0; }
file_lacks()   { grep -q -- "$2" "$1" 2>/dev/null && echo 0 || echo 1; }
exists()       { [[ -e "$1" ]] && echo 1 || echo 0; }
absent()       { [[ ! -e "$1" ]] && echo 1 || echo 0; }
# A backup of <basename> exists under BACKUP_BASE ?
backup_for()   { find "$BACKUP_BASE" -name "$1" 2>/dev/null | grep -q . && echo 1 || echo 0; }
# No backup of <basename> (for dry-run, which must not back up) ?
no_backup_for(){ find "$BACKUP_BASE" -name "$1" 2>/dev/null | grep -q . && echo 0 || echo 1; }
# <pattern> appears somewhere in the backups ?
backup_grep()  { grep -rl -- "$1" "$BACKUP_BASE" 2>/dev/null | grep -q . && echo 1 || echo 0; }
# <dir> contains nothing but .git ?
dir_only_git() { [[ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name .git -print -quit 2>/dev/null)" ]] && echo 1 || echo 0; }

# verdict -> write RESULT.txt (PASS/FAIL) and exit accordingly.
verdict() {
  if [[ "$_FAILS" -eq 0 ]]; then
    printf 'PASS\n' >"$RESULT"; echo "==> PASS"
  else
    printf 'FAIL (%s assertion(s))\n' "$_FAILS" >"$RESULT"; echo "==> FAIL ($_FAILS)"
  fi
  # drop the out-of-repo workspace; log + result stay in the case folder
  rm -rf "$RUN_TMP"
  [[ "$_FAILS" -eq 0 ]]
}
