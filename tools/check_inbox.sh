#!/bin/bash
set -u
cd "$(dirname "$0")/.."

T=$(mktemp -d)
trap "rm -rf $T" EXIT

mkdir -p "$T/PX/a" "$T/PX/b" "$T/PX/c/d/e"

# Folder a: date 2026-11-10, brief b1, role researcher, model m1, clean yes
# Format: date plan brief role model vehicle exit cause minutes bytes report checks clean session
cat > "$T/PX/a/status.tsv" <<'EOF'
# comment line
2026-11-10	PX	b1	researcher	m1	kilo	0	ok	5	100	DONE	PASS	yes	s1
EOF

# Folder b: date 2026-11-12, brief b2, clean no
cat > "$T/PX/b/status.tsv" <<'EOF'
2026-11-12	P-001	b2	builder	kilo	B1	0	OK	20	2048	report.txt	PASS	no	sess-b
EOF

# Folder c/d/e: date 2026-11-11, brief b3
cat > "$T/PX/c/d/e/status.tsv" <<'EOF'
2026-11-11	P-001	b3	builder	kilo	C1	0	OK	10	512	report.txt	PASS	yes	sess-c
EOF

# Test 1: Run inbox.py with the test data
OUTPUT=$(python3 -I tools/inbox.py PX --root "$T" 2>&1)
FIRST_LINE=$(echo "$OUTPUT" | head -1)

if [[ "$FIRST_LINE" == "INBOX PX: 3 runs" ]]; then
  CHECK1="PASS"
  GOT1="INBOX PX: 3 runs"
else
  CHECK1="FAIL"
  GOT1="$FIRST_LINE"
fi
echo "CHECK inbox.py runs PASS|FAIL: $CHECK1 - $GOT1"

# Test 2: Verify order (b2, b3, b1) - newest first
LINE2=$(echo "$OUTPUT" | sed -n '2p')
LINE3=$(echo "$OUTPUT" | sed -n '3p')
LINE4=$(echo "$OUTPUT" | sed -n '4p')

# Check that the lines contain b2, b3, b1 in that order
if echo "$LINE2" | grep -q "b2" && echo "$LINE3" | grep -q "b3" && echo "$LINE4" | grep -q "b1"; then
  CHECK2="PASS"
  GOT2="b2, b3, b1 in order"
else
  CHECK2="FAIL"
  GOT2="b2=$(echo "$LINE2" | grep -o 'b[0-9]'), b3=$(echo "$LINE3" | grep -o 'b[0-9]'), b1=$(echo "$LINE4" | grep -o 'b[0-9]')"
fi
echo "CHECK order correct PASS|FAIL: $CHECK2 - $GOT2"

# Test 3: Test jl inbox NOPLAN
cd "$(cd "$(dirname "$0")/.." && pwd)"
NO_PLAN_OUTPUT=$(bash jl inbox NOPLAN --root "$T" 2>&1)
NO_PLAN_FIRST=$(echo "$NO_PLAN_OUTPUT" | head -1)

if [[ "$NO_PLAN_FIRST" == "INBOX NOPLAN: 0 runs" ]]; then
  CHECK3="PASS"
  GOT3="INBOX NOPLAN: 0 runs"
else
  CHECK3="FAIL"
  GOT3="$NO_PLAN_FIRST"
fi
echo "CHECK jl inbox NOPLAN PASS|FAIL: $CHECK3 - $GOT3"

# Test 4: Verify exact output format for b1
EXPECTED_B1="2026-11-10 b1 researcher m1 kilo exit=0 ok 5min report=DONE checks=PASS clean=yes"
if [[ "$LINE4" == "$EXPECTED_B1" ]]; then
  CHECK4="PASS"
  GOT4="$LINE4"
else
  CHECK4="FAIL"
  GOT4="$LINE4"
fi
echo "CHECK b1 format exact PASS|FAIL: $CHECK4 - $GOT4"

# Count passes
PASS_COUNT=0
[ "$CHECK1" = "PASS" ] && ((PASS_COUNT++))
[ "$CHECK2" = "PASS" ] && ((PASS_COUNT++))
[ "$CHECK3" = "PASS" ] && ((PASS_COUNT++))
[ "$CHECK4" = "PASS" ] && ((PASS_COUNT++))

echo "RESULT $PASS_COUNT/4"

# Exit with code 1 if any check failed
if [ "$PASS_COUNT" -ne 4 ]; then
  exit 1
fi
