#!/bin/bash
# check_mem_index.sh · v1.0 · 2026-11-19 · written by the Brain Creator (P-006 W2, P-005 R3).
# The oracle for tools/mem_index.py. Never edited by the worker that builds it (H4).
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
P="python3 -I $R/tools/mem_index.py"
T=$(mktemp -d)
PASS=0; FAIL=0
ok()  { echo "CHECK $1 PASS"; PASS=$((PASS+1)); }
bad() { echo "CHECK $1 FAIL: $2"; FAIL=$((FAIL+1)); }

mkdir -p "$T/threads"
w() { printf '%s\n' "# $2" "Tags: $3" "State: OPEN" "" "$4" > "$T/threads/$1.md"; }
w T-01 "Dark mode toggle for the clinic dashboard" "ui theme" "Users asked for a darker theme at night."
w T-02 "SMS reminders before appointments" "sms reminder" "Send a text message to the patient one day before the visit."
w T-03 "Fawry payment gateway" "payment billing" "Clinics collect fees by card through Fawry."
w T-04 "Offline sync for the mobile app" "mobile sync" "The app must keep working without internet and sync later."
w T-05 "Arabic RTL layout" "i18n arabic" "Every screen must read right to left for Arabic users."
w T-06 "Doctor daily schedule view" "doctor schedule" "One screen shows the doctor's visits for today."
w T-07 "Export reports as PDF" "reports export" "Monthly reports download as a PDF file."
w T-08 "Password reset email flow" "auth email" "A reset link goes by email and expires in one hour."
w T-09 "Nightly database backup" "ops backup" "A copy of the data is saved every night at 2 am."
w T-10 "Pricing tier for small clinics" "pricing sales" "A cheaper plan for clinics with one doctor."
w T-11 "Search patients by phone number" "search patients" "The receptionist finds a patient record from a phone number."
w T-12 "Onboarding wizard for a new clinic" "onboarding setup" "Five steps set up a new clinic account."

cat > "$T/dec.md" << 'EOF'
| Date | Decision | Source |
|---|---|---|
| 2026-01-01 | Use Postgres as the database engine for every product. | go |
| 2026-01-02 | Workers run on free Kilo models. | go |
| 2026-01-03 | No deploy on a Friday. | go |
| 2026-01-04 | The logo color is green. | go |
| 2026-01-05 | Clinics get a weekly invoice. | go |
EOF

cat > "$T/cards.md" << 'EOF'
# Cards
## Cards
### C-jl-001 git worktree per brief
Try first: make one git worktree for each brief before any edit.
### C-jl-002 npm ci cache
Try first: link the shared node_modules instead of a fresh npm ci.
### C-jl-003 playwright screenshot
Try first: wait for network idle before a Playwright screenshot.
EOF

printf '%s\n' "# fixture" "threads/*.md	file	thread" "dec.md	rows	decision" "cards.md	sections	card" > "$T/roots.tsv"
F="--roots $T/roots.tsv --base $T"

# 1. list: 20 docs, each id once
L=$($P $F list 2>&1)
N=$(printf '%s\n' "$L" | grep -c $'\t')
U=$(printf '%s\n' "$L" | grep $'\t' | cut -f1 | sort -u | wc -l)
if [ "$N" = 20 ] && [ "$U" = 20 ] && printf '%s\n' "$L" | tail -1 | grep -qx 'DOCS: 20'; then ok list
else bad list "rows=$N unique=$U last=$(printf '%s\n' "$L" | tail -1)"; fi

# 2. ten queries: the right doc in the top 3
q() {
  OUT=$($P $F recall "$1" 2>&1)
  if printf '%s\n' "$OUT" | head -3 | cut -f1 | grep -qxF "$2"; then ok "recall '$1'"
  else bad "recall '$1'" "want $2, got: $(printf '%s' "$OUT" | cut -f1 | tr '\n' ' ')"; fi
}
q "text message reminder before appointment" "threads/T-02.md"
q "Fawry card payments" "threads/T-03.md"
q "app works without internet" "threads/T-04.md"
q "right to left arabic" "threads/T-05.md"
q "pdf report export" "threads/T-07.md"
q "nightly backup of the database" "threads/T-09.md"
q "which database engine" "dec.md:3"
q "friday deploy" "dec.md:5"
q "worktree for each brief" "cards.md#C-jl-001 git worktree per brief"
q "find patient by phone" "threads/T-11.md"

# 3. output form: at most 3 lines, 3 tab-separated fields
OUT=$($P $F recall "clinic" 2>&1)
if [ "$(printf '%s\n' "$OUT" | wc -l)" -le 3 ] && ! printf '%s\n' "$OUT" | awk -F'\t' 'NF!=3{e=1} END{exit !e}'; then ok form
else bad form "$OUT"; fi

# 4. no match, exit 0
OUT=$($P $F recall "zzqx" 2>&1); RC=$?
[ "$OUT" = "NO MATCH" ] && [ $RC = 0 ] && ok nomatch || bad nomatch "rc=$RC out=$OUT"

# 5. bad usage exits 2
$P $F recall >/dev/null 2>&1; RC=$?
[ $RC = 2 ] && ok usage || bad usage "rc=$RC"

# 6. a checked lesson ranks above the same text unchecked
mkdir -p "$T/b"
printf '%s\n' "# A" "- [process] [unchecked] alpha beta gamma" > "$T/b/a.md"
printf '%s\n' "# B" "- [process] [checked] alpha beta gamma" > "$T/b/b.md"
printf '%s\n' "b/*.md	file	thread" > "$T/r2.tsv"
OUT=$($P --roots "$T/r2.tsv" --base "$T" recall "alpha beta gamma" 2>&1)
[ "$(printf '%s\n' "$OUT" | head -1 | cut -f1)" = "b/b.md" ] && ok checked || bad checked "$OUT"

# 7. the real repo: T-001 found, every decision row listed, under 1 second
cd /tmp
S=$(date +%s%N)
OUT=$($P recall "security review when we plan a feature" 2>&1)
E=$(( ($(date +%s%N) - S) / 1000000 ))
printf '%s\n' "$OUT" | head -3 | cut -f1 | grep -qx 'agents/memory/wise-man/threads/T-001.md' && ok "real T-001" || bad "real T-001" "$OUT"
[ $E -lt 1000 ] && ok "speed ${E}ms" || bad speed "${E}ms"
WANT=$(grep -c '^| 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' $R/memory/decisions.md)
GOT=$($P list 2>/dev/null | grep -c $'\tdecision\t')
[ "$WANT" = "$GOT" ] && ok "real decisions $GOT" || bad "real decisions" "want $WANT got $GOT"

# 8. START under 400 words
WC=$(wc -w < $R/agents/memory/wise-man/START.md)
[ "$WC" -lt 400 ] && ok "start ${WC}w" || bad start "${WC}w"

# 9. relative roots from cwd
cd "$T"
OUT1=$($P --roots roots.tsv --base "$T" list 2>&1)
cd "$R"
OUT2=$($P --roots "$T/roots.tsv" --base "$T" list 2>&1)
if [ "$OUT1" = "$OUT2" ] && [ $? = 0 ]; then ok "relative roots from cwd"
else bad "relative roots from cwd" "mismatch"; fi

rm -rf "$T"
echo "RESULT: $PASS pass, $FAIL fail"
[ $FAIL = 0 ]
