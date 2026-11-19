#!/bin/bash
# check_sec_score.sh v1.2: checks tools/sec_score.py on a made-up key (plan P-003 S3).
# Run from the folder that holds tools/. Prints PASS or FAIL per case, then RESULT n/8; exit 0 only at 8/8.
set -u
T=$(mktemp -d)
mkdir "$T/key"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  app id state file start end \
  app-1 S01 open routes/a.js 5 10 \
  app-1 S02 open routes/a.js 11 20 \
  app-1 S03 open config.js 1 8 \
  app-1 S03 open lib/b.js 1 3 \
  app-1 T1 safe routes/a.js 21 30 \
  app-2 S01 closed routes/a.js 5 12 \
  app-2 T1 safe routes/a.js 21 30 > "$T/key/where.tsv"
cat > "$T/f1.md" <<'EOF'
AGENT: sec-authz    BRIEF: x    COMMIT: abc    RESULT: FINDINGS
FINDING A1: HIGH    CHECK: 2
  WHERE: routes/a.js:7 · getThing
  ATTACK: as staff of tenant A, call getThing with config.js:3 -> gets it
FINDING A2: HIGH    CHECK: 2
  WHERE: ./app-1/routes/a.js:9 · getThing
FINDING A3: LOW    CHECK: 9
  WHERE: `lib/b.js:2` · helper
FINDING A4: LOW    CHECK: 9
  WHERE: routes/a.js:25 · backup
FINDING A5: LOW    CHECK: 9
  WHERE: lib/store.js:4 · users
FINDING A6: LOW    CHECK: 9
  WHERE: xroutes/a.js:7 · other
UNCLEAR: None
EOF
cat > "$T/f2.md" <<'EOF'
  WHERE: routes/a.js:10 · last line of S01
  WHERE: routes/a.js:11 · first line of S02
  WHERE: routes/a.js:4 · one line before S01
  WHERE: routes/a.js:4 · the same place again
EOF
: > "$T/empty.md"
n=0
ok() { if [ "$2" = "$3" ]; then echo "PASS $1"; n=$((n+1)); else echo "FAIL $1"; echo "got: $2"; echo "want: $3"; fi; }
run() { python3 -I tools/sec_score.py "$@" 2>/dev/null; }
ok "app-1" "$(run "$T/f1.md" app-1 "$T/key")" "$(printf 'FINDINGS 6\nFOUND 2/3\nMISSED: S02\nFALSE ALARMS 1: T1\nUNSCORED 2: lib/store.js:4 xroutes/a.js:7')"
ok "app-2" "$(run "$T/f1.md" app-2 "$T/key")" "$(printf 'FINDINGS 6\nFOUND 0/0\nMISSED: None\nFALSE ALARMS 2: S01 T1\nUNSCORED 3: lib/b.js:2 lib/store.js:4 xroutes/a.js:7')"
ok "edges" "$(run "$T/f2.md" app-1 "$T/key")" "$(printf 'FINDINGS 4\nFOUND 2/3\nMISSED: S03\nFALSE ALARMS 0: None\nUNSCORED 2: routes/a.js:4 routes/a.js:4')"
ok "clean report" "$(run "$T/empty.md" app-1 "$T/key")" "$(printf 'FINDINGS 0\nFOUND 0/3\nMISSED: S01 S02 S03\nFALSE ALARMS 0: None\nUNSCORED 0: None')"
mkdir "$T/key2"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  app id state file start end \
  app-1 S01 open a.js 1 10 \
  app-1 S02 open a.js 5 12 \
  app-1 T1 safe a.js 8 9 > "$T/key2/where.tsv"
printf '  WHERE: a.js:8 - one place inside three rows\n  WHERE: ./other.js:3 - outside the key\n' > "$T/f3.md"
ok "one finding hits every row it is inside" "$(run "$T/f3.md" app-1 "$T/key2")" "$(printf 'FINDINGS 2\nFOUND 2/2\nMISSED: None\nFALSE ALARMS 1: T1\nUNSCORED 1: other.js:3')"
bad() { e=$(python3 -I tools/sec_score.py "$@" 2>&1 >/dev/null); echo "$? ${e:0:7}"; }
ok "unknown app exits 2" "$(bad "$T/f1.md" app-9 "$T/key")" "2 ERROR: "
ok "missing findings file exits 2" "$(bad "$T/none.md" app-1 "$T/key")" "2 ERROR: "
ok "missing key folder exits 2" "$(bad "$T/f1.md" app-1 "$T/nokey")" "2 ERROR: "
rm -rf "$T"
echo "RESULT $n/8"
[ "$n" -eq 8 ]
