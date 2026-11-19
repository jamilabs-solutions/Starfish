#!/usr/bin/env bash
# check_kilo_watch_ids.sh v1.1: fixtures for kilo_watch.py --id-of, --tools-of and --tokens-of (P-001 M1c-1)
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); DB=$T/k.db; n=0
python3 -I - "$DB" <<'PY'
import sqlite3, sys, json
c = sqlite3.connect(sys.argv[1])
c.execute("create table session (id text, title text, time_created int, time_updated int, tokens_input int, tokens_output int, tokens_reasoning int, tokens_cache_read int)")
c.execute("create table part (session_id text, time_created int, time_updated int, data text)")
c.execute("insert into session values ('ses_old', 'T1 m 1', 1, 1, 0, 0, 0, 0), ('ses_new', 'T1 m 1', 2, 2, 10, 20, 3, 400)")
for t, d in [(1, {"type": "tool", "tool": "bash", "state": {"input": {"command": "ls -la"}}}),
             (2, {"type": "text", "text": "hi"}),
             (3, {"type": "tool", "tool": "read", "state": {"input": {"filePath": "/x"}}}),
             (4, {"type": "tool", "tool": "bash", "state": {"input": {"command": "cd /tmp &&\n  echo hi"}}})]:
    c.execute("insert into part values ('ses_new', ?, ?, ?)", (t, t, json.dumps(d)))
c.commit()
PY
ok() { if [ "$2" = "$3" ]; then echo "PASS $1"; n=$((n+1)); else echo "FAIL $1: got [$2] want [$3]"; fi; }
ok "id-of newest" "$(python3 -I tools/kilo_watch.py --db "$DB" --id-of 'T1 m 1'; echo "exit=$?")" "ses_new
exit=0"
ok "id-of missing" "$(python3 -I tools/kilo_watch.py --db "$DB" --id-of 'nope'; echo "exit=$?")" "none
exit=1"
ok "tools-of" "$(python3 -I tools/kilo_watch.py --db "$DB" --tools-of ses_new; echo "exit=$?")" "ls -la
cd /tmp && echo hi
exit=0"
ok "tokens-of" "$(python3 -I tools/kilo_watch.py --db "$DB" --tokens-of ses_new)" "433"
ok "tokens-of missing" "$(python3 -I tools/kilo_watch.py --db "$DB" --tokens-of nope)" "0"
rm -rf "$T"
echo "RESULT $n/5"