#!/usr/bin/env bash
set -u

T=$(mktemp -d)
RESULT_PASS=0
RESULT_FAIL=0

# Fixture 1: kilo.txt "AGENT: t RESULT: DONE"; check echo ok / ^ok; exit 0; expect 0 ok DONE PASS yes
FIXTURE_DIR="$T/fixture1"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: t RESULT: DONE" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "ok" ] && [ "$REPORT" = "DONE" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "yes" ]; then
    echo "FIXTURE 1 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 1 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 2: kilo.txt "AGENT: t RESULT: DONE"; check echo bad / ^ok; exit 0; expect 0 ok DONE FAIL no
FIXTURE_DIR="$T/fixture2"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: t RESULT: DONE" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo bad\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "ok" ] && [ "$REPORT" = "DONE" ] && [ "$CHECKS" = "FAIL" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 2 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 2 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 3: kilo.txt "just chatter"; check as 1; exit 0; expect 0 no-report NONE PASS no
FIXTURE_DIR="$T/fixture3"
mkdir -p "$FIXTURE_DIR"
echo "just chatter" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "no-report" ] && [ "$REPORT" = "NONE" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 3 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 3 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 4: template line only; check as 1; exit 0; expect 0 no-report NONE PASS no
FIXTURE_DIR="$T/fixture4"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: <role> RESULT: DONE | STOPPED" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "no-report" ] && [ "$REPORT" = "NONE" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 4 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 4 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 5: kilo.txt "AGENT: t RESULT: DONE"; check as 1; exit 124; expect 124 timeout DONE PASS no
FIXTURE_DIR="$T/fixture5"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: t RESULT: DONE" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 124 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "124" ] && [ "$CAUSE" = "timeout" ] && [ "$REPORT" = "DONE" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 5 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 5 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 6: kilo.txt "AGENT: t RESULT: DONE"; no checks block; exit 0; expect 0 ok DONE NONE no
FIXTURE_DIR="$T/fixture6"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: t RESULT: DONE" > "$FIXTURE_DIR/kilo.txt"
printf "No checks here\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "ok" ] && [ "$REPORT" = "DONE" ] && [ "$CHECKS" = "NONE" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 6 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 6 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 7: NO-FINDINGS check
FIXTURE_DIR="$T/fixture7"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: t RESULT: DONE" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo RESULT: NO-FINDINGS\nPASS-IF NO-FINDINGS\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "ok" ] && [ "$REPORT" = "DONE" ] && [ "$CHECKS" = "NO-FINDINGS" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 7 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 7 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixtures 8-10: run mode with a fake Kilo that writes its own session into a fake db (P-001 M1c-3)
cat > "$T/fakekilo" <<'PY'
#!/usr/bin/env python3
import sys, sqlite3, json, os, time
title = sys.argv[sys.argv.index('--title') + 1]
mode = os.environ['FAKE_MODE']
if mode == 'slow':
    time.sleep(5)
c = sqlite3.connect(os.environ['FAKE_DB'])
c.execute("insert into session values ('ses_f', ?, 1, 1)", (title,))
c.execute("insert into part values ('ses_f', 1, 1, ?)", (json.dumps({"type": "tool", "tool": "bash", "state": {"input": {"command": "cd /x && echo hi"}}}),))
c.commit()
print("AGENT: builder    BRIEF: B    RESULT: DONE")
print("CHECKS:")
print("RAN echo hi")
if mode == 'lie':
    print("RAN rm -rf /nothing")
PY
chmod +x "$T/fakekilo"
run_fixture() {  # run_fixture <n> <mode> <timeout> <expected cols 7,8,11,12,13,14> <expected checks.txt line>
    local D="$T/fixture$1"
    mkdir -p "$D"
    python3 -I -c "import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute('create table session (id text, title text, time_created int, time_updated int)'); c.execute('create table part (session_id text, time_created int, time_updated int, data text)'); c.commit()" "$D/k.db"
    printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$D/brief.txt"
    echo "do it" > "$D/prompt.txt"
    FAKE_MODE=$2 FAKE_DB="$D/k.db" JL_KILO="$T/fakekilo" python3 -I tools/jl_runner.py run --dir "$D" --brief-file "$D/brief.txt" --prompt-file "$D/prompt.txt" --plan P --brief B --role R --model m/M --vehicle kilo --timeout "$3" --db "$D/k.db" > "$D/status.line"
    local GOT
    GOT=$(cut -f7,8,11,12,13,14 --output-delimiter=' ' "$D/status.line")
    if [ "$GOT" = "$4" ] && grep -qx "$5" "$D/checks.txt"; then
        echo "FIXTURE $1 PASS"
        ((RESULT_PASS++))
    else
        echo "FIXTURE $1 FAIL: got [$GOT] want [$4]; checks.txt: $(tr '\n' '|' < "$D/checks.txt")"
        ((RESULT_FAIL++))
    fi
}
run_fixture 8 ok 60 "0 ok DONE PASS yes ses_f" "TOOLLOG PASS 1/1"
run_fixture 9 lie 60 "0 ok DONE FAIL no ses_f" "TOOLLOG MISSING rm -rf /nothing"
run_fixture 10 slow 1 "124 timeout NONE PASS no none" "TOOLLOG SKIPPED no session (0 RAN lines)"

# Fixture 11: auditor RESULT word FINDINGS is accepted; clean yes; expect 0 ok FINDINGS PASS yes
FIXTURE_DIR="$T/fixture11"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: sniper    BRIEF: x    COMMIT: abc    RESULT: FINDINGS" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "ok" ] && [ "$REPORT" = "FINDINGS" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "yes" ]; then
    echo "FIXTURE 11 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 11 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

# Fixture 12: template line "RESULT: CLEAN | FINDINGS" is skipped; expect 0 no-report NONE PASS no
FIXTURE_DIR="$T/fixture12"
mkdir -p "$FIXTURE_DIR"
echo "AGENT: sniper    BRIEF: <id>    COMMIT: <hash>    RESULT: CLEAN | FINDINGS" > "$FIXTURE_DIR/kilo.txt"
printf "## Machine checks\nCHECK echo ok\nPASS-IF ^ok\n" > "$FIXTURE_DIR/brief.txt"
python3 -I tools/jl_runner.py finish --dir "$FIXTURE_DIR" --brief-file "$FIXTURE_DIR/brief.txt" --plan P --brief B --role R --model M --vehicle V --exit 0 --minutes 10 > "$FIXTURE_DIR/status.line"
EXIT=$(cut -f7 "$FIXTURE_DIR/status.line")
CAUSE=$(cut -f8 "$FIXTURE_DIR/status.line")
REPORT=$(cut -f11 "$FIXTURE_DIR/status.line")
CHECKS=$(cut -f12 "$FIXTURE_DIR/status.line")
CLEAN=$(cut -f13 "$FIXTURE_DIR/status.line")
if [ "$EXIT" = "0" ] && [ "$CAUSE" = "no-report" ] && [ "$REPORT" = "NONE" ] && [ "$CHECKS" = "PASS" ] && [ "$CLEAN" = "no" ]; then
    echo "FIXTURE 12 PASS"
    ((RESULT_PASS++))
else
    echo "FIXTURE 12 FAIL: got $EXIT $CAUSE $REPORT $CHECKS $CLEAN"
    ((RESULT_FAIL++))
fi

TOTAL=$((RESULT_PASS + RESULT_FAIL))
echo "RESULT $RESULT_PASS/$TOTAL"

rm -rf "$T"

if [ $RESULT_FAIL -gt 0 ]; then
    exit 1
else
    exit 0
fi
