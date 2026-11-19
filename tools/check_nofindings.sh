#!/bin/bash
set -u

T=$(mktemp -d)
cd "$(cd "$(dirname "$0")/.." && pwd)"

# Write findings file
cat > "$T/f.md" << 'EOF'
# Research x
## Answers
### Q1 q
- NOT FOUND: searched "a"
## Sources
| ID | URL | Quote | Page date |
EOF

# Run research_check
output=$(python3 -I tools/research_check.py "$T/f.md" 2>&1)
exit_status=$?

# Assert 1: output contains RESULT: NO-FINDINGS
if echo "$output" | grep -q "RESULT: NO-FINDINGS"; then
  echo "CHECK no-findings output PASS: $output"
  check1=1
else
  echo "CHECK no-findings output FAIL: $output"
  check1=0
fi

# Assert 2: exit status is 1
if [ "$exit_status" -eq 1 ]; then
  echo "CHECK exit status PASS: 1"
  check2=1
else
  echo "CHECK exit status FAIL: $exit_status"
  check2=0
fi

# Assert 3: grep -c finds exactly 1 Machine checks section
count=$(grep -c "^## Machine checks" templates/brief.md)
if [ "$count" -eq 1 ]; then
  echo "CHECK brief machine checks PASS: $count"
  check3=1
else
  echo "CHECK brief machine checks FAIL: $count"
  check3=0
fi

# Report and cleanup
rm -rf "$T"

passed=$((check1 + check2 + check3))
echo "RESULT $passed/3"

if [ "$passed" -ne 3 ]; then
  exit 1
fi
