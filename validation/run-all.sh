#!/usr/bin/env bash
# Run every validation case and print a summary table.
# Each case writes its own RESULT.txt (PASS/FAIL) and output.log in its folder.
# Usage: ./run-all.sh            (run all)
#        ./run-all.sh 04 50      (run only cases whose name starts with 04 / 50)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cases=("$HERE"/cases/*/)
pass=0; fail=0
printf '\n%-34s %s\n' "CASE" "RESULT"
printf '%s\n' "------------------------------------------------"
for dir in "${cases[@]}"; do
  name="$(basename "$dir")"
  if [[ $# -gt 0 ]]; then
    match=0; for pat in "$@"; do [[ "$name" == "$pat"* ]] && match=1; done
    [[ "$match" == 1 ]] || continue
  fi
  bash "$dir/run.sh" >/dev/null 2>&1
  res="$(cat "$dir/RESULT.txt" 2>/dev/null || echo 'NO RESULT')"
  if [[ "$res" == PASS ]]; then pass=$((pass+1)); mark="✅"; else fail=$((fail+1)); mark="❌"; fi
  printf '%-34s %s %s\n' "$name" "$mark" "$res"
done
printf '%s\n' "------------------------------------------------"
printf 'TOTAL: %s passed, %s failed\n\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
