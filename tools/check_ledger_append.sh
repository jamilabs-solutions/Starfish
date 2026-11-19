#!/bin/bash
set -u
T=$(mktemp -d)
trap "rm -rf \"$T\"" EXIT

mkdir -p "$T/root"/{A,B,C,D}
mkdir -p "$T/ev"

echo -e "2026-11-12\tP-001\tbA\tresearcher\tm1\tkilo-headless\t0\tok\t5\t100\tDONE\tPASS\tyes\ts" > "$T/root/A/status.tsv"
echo -e "2026-11-12\tP-001\tbB\tresearcher\tm1\tkilo-headless\t0\tno-report\t5\t100\tNONE\tNONE\tno\ts" > "$T/root/B/status.tsv"
echo -e "2026-11-12\tP-001\tbC\tresearcher\tm1\tkilo-headless\t0\tok\t5\t100\tDONE\tFAIL\tno\ts" > "$T/root/C/status.tsv"
echo -e "2026-11-12\tP-001\tbA\tresearcher\tm1\tkilo-headless\t0\tok\t5\t100\tDONE\tPASS\tyes\ts" > "$T/root/D/status.tsv"

first_run=$(python3 -I tools/ledger.py append "$T/root" --events-dir "$T/ev")
first_line_count=$(wc -l < "$T/ev/researcher.events.tsv")
ok_values=$(cut -f9 "$T/ev/researcher.events.tsv" | tail -5 | paste -sd ',' -)

second_run=$(python3 -I tools/ledger.py append "$T/root" --events-dir "$T/ev")
second_line_count=$(wc -l < "$T/ev/researcher.events.tsv")

pass_count=0
total_count=4

if [ "$first_run" = "appended 5 rows from 3 folders" ]; then
  echo "CHECK first-run PASS"
  ((pass_count++))
else
  echo "CHECK first-run FAIL: $first_run"
fi

if [ "$first_line_count" = "6" ]; then
  echo "CHECK line-count PASS"
  ((pass_count++))
else
  echo "CHECK line-count FAIL: got $first_line_count"
fi

if [ "$ok_values" = "yes,no,no,no,no" ]; then
  echo "CHECK ok-values PASS"
  ((pass_count++))
else
  echo "CHECK ok-values FAIL: got $ok_values"
fi

if [ "$second_run" = "appended 0 rows from 0 folders" ] && [ "$second_line_count" = "6" ]; then
  echo "CHECK second-run PASS"
  ((pass_count++))
else
  echo "CHECK second-run FAIL: $second_run (lines: $second_line_count)"
fi

echo "RESULT $pass_count/4"
[ "$pass_count" -eq 4 ] || exit 1
