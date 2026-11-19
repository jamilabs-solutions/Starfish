#!/usr/bin/env bash
# Acceptance check for make_resume_pack.sh. Prints ALL 5 CHECKS PASSED or the first failing check.
here="$(cd "$(dirname "$0")" && pwd)"
t="$(mktemp -d)"
git -C "$t" init -q -b main && git -C "$t" config user.email a@b.c && git -C "$t" config user.name t
echo one > "$t/f.txt" && git -C "$t" add f.txt && git -C "$t" commit -q -m "first commit"
mkdir -p "$t/.jamilabs/runs"
{ echo "# Run log"; echo; echo "| Date | Brief |"; echo "|---|---|"; for i in 1 2 3 4 5 6 7 8 9 10; do echo "| 2026-10-24 | brief-$i |"; done; } > "$t/.jamilabs/runs/LOG.md"
out="$(bash "$here/make_resume_pack.sh" "$t" "Audit brief-10, then write brief-11.")"
echo "$out" | grep -qF "Audit brief-10, then write brief-11." || { echo "FAIL 1: NEXT sentence missing"; exit 1; }
echo "$out" | grep -qF "branch: main" || { echo "FAIL 2: branch line missing"; exit 1; }
[ "$(echo "$out" | grep -c '^| 20')" = "8" ] || { echo "FAIL 3: expected exactly 8 run rows"; exit 1; }
echo "$out" | grep -qF "| brief-10 |" && ! echo "$out" | grep -qF "| brief-2 |" || { echo "FAIL 4: wrong run rows kept"; exit 1; }
out2="$(bash "$here/make_resume_pack.sh" "$t" "x" "$t/missing.md")"
echo "$out2" | grep -qF "no run log at $t/missing.md" || { echo "FAIL 5: missing log not reported"; exit 1; }
echo "ALL 5 CHECKS PASSED"
