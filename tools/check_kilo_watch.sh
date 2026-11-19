#!/bin/bash
set -u

# Build fixture database
TMPDIR=$(mktemp -d)
DB="$TMPDIR/kilo.db"
LOG="$TMPDIR/test.log"
export LOG_PATH="$LOG"

python3 << PYTHON_END
import sqlite3, json
conn = sqlite3.connect("$DB")
c = conn.cursor()

c.execute('''
    CREATE TABLE session (
        id TEXT PRIMARY KEY,
        title TEXT,
        model TEXT,
        time_created INTEGER,
        time_updated INTEGER,
        tokens_input INTEGER,
        tokens_output INTEGER
    )
''')
c.execute('''
    CREATE TABLE message (
        session_id TEXT,
        time_created INTEGER,
        data TEXT
    )
''')
c.execute('''
    CREATE TABLE part (
        session_id TEXT,
        time_updated INTEGER,
        data TEXT
    )
''')

now = 1000000000000

# 1. T done: created now-20min, last part now-5min, last assistant finish=stop -> DONE
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s1', 'T done', '{"id":"test","providerID":"kilo"}', now-1200000, now-300000, 1000, 500))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s1', now-300000, json.dumps({'type': 'tool', 'tool': 'write', 'state': {'status': 'success', 'title': 'file.txt'}})))
c.execute('INSERT INTO message VALUES (?,?,?)',
    ('s1', now-300000, json.dumps({'role': 'assistant', 'finish': 'stop'})))

# 2. T rejected: last part now-6min, last assistant error auto-rejected permission -> FAILED permission rejected
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s2', 'T rejected', 'kilo/test', now-1200000, now-360000, 2000, 1000))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s2', now-360000, json.dumps({'type': 'tool', 'tool': 'write', 'state': {'status': 'success', 'title': 'file.txt'}})))
c.execute('INSERT INTO message VALUES (?,?,?)',
    ('s2', now-360000, json.dumps({'role': 'assistant', 'error': {'name': 'UnknownError', 'data': {'message': 'run ended with an auto-rejected permission'}}})  ))

# 3. T broken: last part now-8min, tool part error invalid arguments, last assistant no error -> FAILED broken tool call
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s3', 'T broken', 'kilo/test', now-1200000, now-480000, 1500, 800))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s3', now-480000, json.dumps({'type': 'tool', 'tool': 'write', 'state': {'status': 'error', 'error': 'The write tool was called with invalid arguments'}})))
c.execute('INSERT INTO message VALUES (?,?,?)',
    ('s3', now-480000, json.dumps({'role': 'assistant'})))

# 4. T timeout: last assistant error message 'Upstream idle timeout exceeded' -> FAILED provider timeout
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s4', 'T timeout', 'kilo/test', now-1200000, now-600000, 3000, 2000))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s4', now-600000, json.dumps({'type': 'tool', 'tool': 'webfetch', 'state': {'status': 'success', 'title': 'https://example.com'}})))
c.execute('INSERT INTO message VALUES (?,?,?)',
    ('s4', now-600000, json.dumps({'role': 'assistant', 'error': {'name': 'TimeoutError', 'data': {'message': 'Upstream idle timeout exceeded'}}})  ))

# 5. T starting: created now-1min, one part now-1min tool webfetch running, no assistant -> WORKING
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s5', 'T starting', 'kilo/test', now-60000, now-60000, 0, 0))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s5', now-60000, json.dumps({'type': 'tool', 'tool': 'webfetch', 'state': {'status': 'running', 'title': 'https://example.com'}})))

# 6. T old: time_updated now-3hours -> not shown
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s6', 'T old', 'kilo/test', now-10800000, now-10800000, 5000, 3000))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s6', now-10800000, json.dumps({'type': 'tool', 'tool': 'write', 'state': {'status': 'success', 'title': 'old.txt'}})))

# 7. T limited: created now-10min, last part now-4min, text part, no assistant, rate limit lines in log
c.execute('INSERT INTO session VALUES (?,?,?,?,?,?,?)',
    ('s7', 'T limited', 'kilo/test', now-600000, now-240000, 1000, 500))
c.execute('INSERT INTO part VALUES (?,?,?)',
    ('s7', now-240000, json.dumps({'type': 'text'})))

conn.commit()
conn.close()

# Create fixture log with rate limit errors
import os, datetime
log_dir = os.path.dirname(os.environ.get('LOG_PATH', ''))
os.makedirs(log_dir, exist_ok=True)
with open(os.environ.get('LOG_PATH'), 'w') as f:
    now_sec = now / 1000
    now_minus_2min = now_sec - 120
    now_str = datetime.datetime.utcfromtimestamp(now_minus_2min).isoformat()
    for i in range(3):
        f.write(f'timestamp={now_str}Z level=ERROR message="stream error" session.id=s7 error.error="AI_APICallError: Too Many Requests"\n')

PYTHON_END

# Expected output (reasoned from rules)
# now=1000000000000ms
# T done: last_ms=now-300000=999700000, idle_min=(300000)/60000=5, total_min=(999700000-(now-1200000))/60000=900000/60000=15, alive=False, last_assistant finish=stop -> DONE
# T rejected: last_ms=now-360000=999640000, idle_min=6, total_min=14, alive=False, last_assistant error -> FAILED permission rejected
# T broken: last_ms=now-480000=999520000, idle_min=8, total_min=12, alive=False, last_assistant no error but error part -> FAILED broken tool call
# T timeout: last_ms=now-600000=999400000, idle_min=10, total_min=10, alive=False, last_assistant error timeout -> FAILED provider timeout
# T starting: last_ms=now-60000=999940000, idle_min=1, total_min=1, alive=False, idle<2 -> WORKING, action=webfetch https://example.com
# T old: time_updated=now-10800000 < now-3600000 -> not shown

EXPECTED="STATE    MIN  IDLE  TOKENS   MODEL                 TITLE                          LAST ACTION / REASON
LIMITED     6     4       1k test                   T limited                       rate limited (3 in 10 min)
FAILED     12     8       2k test                   T broken                        broken tool call
FAILED     14     6       3k test                   T rejected                      permission rejected
FAILED     10    10       5k test                   T timeout                       provider timeout
WORKING     0     1        0 test                   T starting                      webfetch https://example.com
DONE       15     5       1k test                   T done                          write file.txt
6 sessions · STUCK 0 · LIMITED 1 · FAILED 3 · QUIET 0 · WORKING 1 · DONE 1"

OUTPUT=$(python3 tools/kilo_watch.py --db "$DB" --log "$LOG" --once --no-proc --now-ms 1000000000000 --since-hours 1 2>&1)

if [ "$OUTPUT" = "$EXPECTED" ]; then
    echo "PASS"
    rm -rf "$TMPDIR"
    exit 0
else
    echo "FAIL"
    echo "=== OUTPUT ==="
    echo "$OUTPUT"
    echo "=== EXPECTED ==="
    echo "$EXPECTED"
    echo "=== DIFF ==="
    diff -u <(echo "$EXPECTED") <(echo "$OUTPUT") || true
    rm -rf "$TMPDIR"
    exit 1
fi
