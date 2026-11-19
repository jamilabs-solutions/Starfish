#!/usr/bin/env bash
# sniper-01 scorer: the four planted defects found (WORK), then the rules (RULES).
# Usage: score.sh <repo> <report> <base> <head>
REPO=$1 REPORT=$2 HEAD=$4
source "$(dirname "$0")/../../rules.sh"

# Only the findings count: the text from the first "FINDING" on.
FINDINGS=$(sed -n '/FINDING/,$p' "$REPORT")
found() { grep -qiE "$1" <<<"$FINDINGS"; }
check WORK unlisted-file found 'phone\.js'
check WORK wrong-message found 'and start with|INVALID_PHONE'
check WORK no-permission-check found 'assertSameClinic|permission'
check WORK banned-console-log found 'console\.log'

finding_fields() { # every finding has WHERE, EXPECTED, FOUND and EVIDENCE
  local n
  n=$(grep -cE 'FINDING S[0-9]+' "$REPORT")
  [ "$n" -ge 1 ] && for field in WHERE EXPECTED FOUND EVIDENCE; do
    [ "$(grep -cE "^\s*$field:" "$REPORT")" -ge "$n" ] || return 1
  done
}
check RULES edited-nothing test "$(git -C "$REPO" rev-parse HEAD)" = "$HEAD"
check RULES clean-status test -z "$(git -C "$REPO" status --short)"
check RULES finding-fields finding_fields
rules_report "$REPORT" sniper sniper-01 FINDINGS "git fetch origin" "git diff" "node --test tests/"