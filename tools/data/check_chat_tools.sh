#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILED=0
ok() { echo "PASS $1"; }
bad() { echo "FAIL $1"; FAILED=1; }

python3 - "$TMP" <<'PY'
import datetime
import json
import os
import sys

tmp = sys.argv[1]
base = datetime.datetime(2026, 1, 5, 9, 0, 0)


def make_msgs(count, with_bad=False):
    msgs = []
    for i in range(1, count + 1):
        sender = "Ann" if i % 2 == 1 else "Bob"
        m = {
            "id": i,
            "type": "message",
            "date": (base + datetime.timedelta(minutes=i - 1)).strftime(
                "%Y-%m-%dT%H:%M:%S"
            ),
            "from": sender,
            "text": "m%d" % i,
        }
        if i == 7:
            m["text"] = ["he", {"type": "bold", "text": "llo"}]
        if i == 8:
            m["media_type"] = "voice_message"
        msgs.append(m)
    if with_bad:
        msgs.append({"id": 999, "type": "message", "from": "Ann", "text": "nodate"})
    return msgs


alpha = {"name": "alpha", "messages": make_msgs(250, with_bad=True)}
beta = {"name": "beta", "messages": make_msgs(30)}

with open(os.path.join(tmp, "alpha.json"), "w", encoding="utf-8") as f:
    json.dump(alpha, f)
with open(os.path.join(tmp, "beta.json"), "w", encoding="utf-8") as f:
    json.dump(beta, f)

HEADER = "event\twindow\tfirst_mid\tlast_mid\tdate\tactor\ttarget\ttype\tside\twhat\tquote"


def write_events(path, rows):
    with open(path, "w", encoding="utf-8") as f:
        f.write(HEADER + "\n")
        for r in rows:
            f.write("\t".join(r) + "\n")


def ev(name, window, first, last, type_, side, quote):
    return [name, window, first, last, "", "", "", type_, side, "", quote]


def none(name, window):
    return [name, window, "", "", "", "", "", "NONE", "", "", ""]


valid = [
    ev("E1", "w0001", "alpha:1", "alpha:2", "praise", "neutral", "m1 m2"),
    none("E2", "w0002"),
    none("E3", "w0003"),
    none("E4", "w0004"),
]
write_events(os.path.join(tmp, "valid.tsv"), valid)

valid2 = [
    ev("E1", "w0001", "alpha:1", "alpha:2", "praise", "neutral", "m1 m3"),
    none("E2", "w0002"),
    none("E3", "w0003"),
    none("E4", "w0004"),
]
write_events(os.path.join(tmp, "valid2.tsv"), valid2)

valid3 = [valid[0], valid[1], valid[2]]
write_events(os.path.join(tmp, "valid3.tsv"), valid3)

scolding = [
    ev("E1", "w0001", "alpha:1", "alpha:2", "scolding", "neutral", "m1 m2")
]
write_events(os.path.join(tmp, "scolding.tsv"), scolding)
PY

python3 "$SCRIPT_DIR/chat_prep.py" "$TMP/run" "$TMP/alpha.json" "$TMP/beta.json" > "$TMP/prep.out" 2>&1
PREP_RC=$?

if [ "$PREP_RC" -eq 0 ] && [ "$(cat "$TMP/prep.out")" = "OK messages=280 rejected=1 windows=4 batches=1" ]; then
  ok prep
else
  bad prep
fi

ROW="$(awk -F'\t' 'NR==2{print $1"|"$2"|"$3"|"$4}' "$TMP/run/ledger.tsv")"
if [ "$ROW" = "parse|281|280|1" ]; then
  ok ledger
else
  bad ledger
fi

ALPHA_WIN="$(awk -F'\t' 'NR>1 && $2=="alpha"{print $3" "$4" "$5}' "$TMP/run/windows.tsv" | tr '\n' ';')"
if [ "$ALPHA_WIN" = "alpha:1 alpha:100 100;alpha:86 alpha:185 100;alpha:171 alpha:250 80;" ]; then
  ok windows
else
  bad windows
fi

TEXT="$(awk -F'\t' '$1=="alpha:7"{print $9}' "$TMP/run/messages.tsv")"
if [ "$TEXT" = "hello" ]; then
  ok text
else
  bad text
fi

if grep -q "\[media: voice_message\]" "$TMP/run/batches/batch-001.md"; then
  ok media
else
  bad media
fi

sha256sum "$TMP/alpha.json" "$TMP/beta.json" > "$TMP/actual.sha"
if diff -q "$TMP/actual.sha" "$TMP/run/sha256.txt" > /dev/null; then
  ok sha256
else
  bad sha256
fi

python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" "$TMP/valid.tsv" > "$TMP/c7.out" 2>&1
C7_RC=$?
if [ "$C7_RC" -eq 0 ] && grep -q "QUOTES ok 1 bad 0" "$TMP/c7.out"; then
  ok events_valid
else
  bad events_valid
fi

python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" "$TMP/valid2.tsv" > "$TMP/c8.out" 2>&1
C8_RC=$?
if [ "$C8_RC" -eq 1 ] && grep -q "QUOTES ok 0 bad 1" "$TMP/c8.out"; then
  ok events_quote
else
  bad events_quote
fi

python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" "$TMP/valid3.tsv" > "$TMP/c9.out" 2>&1
C9_RC=$?
if [ "$C9_RC" -eq 1 ] && grep -q "MISSING w0004" "$TMP/c9.out"; then
  ok events_missing
else
  bad events_missing
fi

python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" --diff "$TMP/valid.tsv" "$TMP/scolding.tsv" > "$TMP/c10.out" 2>&1
if grep -q "BOTH 0 ONLY_A 1 ONLY_B 1" "$TMP/c10.out"; then
  ok diff
else
  bad diff
fi

python3 "$SCRIPT_DIR/chat_prep.py" "$TMP/run2" "$TMP/alpha.json" "$TMP/alpha.json" > /dev/null 2>&1
DUP_RC=$?
if [ "$DUP_RC" -eq 2 ]; then
  ok duplicate_stem
else
  bad duplicate_stem
fi

# check 12 scope_dates
FIRST_SCOPE="$(awk -F'\t' '$1=="alpha"{print $4}' "$TMP/run/scope.tsv")"
if [ "$FIRST_SCOPE" = "2026-01-05T09:00:00" ]; then
  ok scope_dates
else
  bad scope_dates
fi

# check 13 bad_overlap
python3 "$SCRIPT_DIR/chat_prep.py" "$TMP/overlaprun" "$TMP/alpha.json" --size 10 --overlap 10 > /dev/null 2>&1
OVERLAP_RC=$?
if [ "$OVERLAP_RC" -eq 2 ]; then
  ok bad_overlap
else
  bad bad_overlap
fi

# separate fixture for forwarded + crlf
python3 - "$TMP" <<'PY'
import json, os, sys, datetime
tmp=sys.argv[1]
base=datetime.datetime(2026,1,5,9,0,0)
msgs=[{"id":1,"type":"message","date":base.strftime("%Y-%m-%dT%H:%M:%S"),"actor":"Ann","text":"a\r\nb","forwarded_from":"Zed","edited":True}]
with open(os.path.join(tmp,"fwd.json"),"w") as f:
    json.dump({"name":"fwd","messages":msgs},f)
PY

python3 "$SCRIPT_DIR/chat_prep.py" "$TMP/fwdrun" "$TMP/fwd.json" > /dev/null 2>&1
FWD_TEXT="$(awk -F'\t' 'NR==2{print $9}' "$TMP/fwdrun/messages.tsv")"
FWD_SENDER="$(awk -F'\t' 'NR==2{print $5}' "$TMP/fwdrun/messages.tsv")"
FWD_FF="$(awk -F'\t' 'NR==2{print $10}' "$TMP/fwdrun/messages.tsv")"
if [ "$FWD_TEXT" = "a b" ] && [ "$FWD_SENDER" = "Ann" ] && [ "$FWD_FF" = "Zed" ]; then
  ok crlf
else
  bad crlf
fi
if grep -q '\[forwarded from: Zed\] \[edited\]' "$TMP/fwdrun/batches/batch-001.md"; then
  ok forwarded
else
  bad forwarded
fi

# check 16 bad_header
printf 'wrong header\n' > "$TMP/badheader.tsv"
python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" "$TMP/badheader.tsv" > "$TMP/bh.out" 2>&1
BH_RC=$?
if [ "$BH_RC" -eq 1 ] && grep -q "BAD HEADER" "$TMP/bh.out"; then
  ok bad_header
else
  bad bad_header
fi

# check 17 outside_window
python3 - "$TMP" <<'PY'
import os, sys
tmp = sys.argv[1]
header = "event\twindow\tfirst_mid\tlast_mid\tdate\tactor\ttarget\ttype\tside\twhat\tquote"
with open(os.path.join(tmp, "outside.tsv"), "w") as f:
    f.write(header + "\n")
    f.write("E1\tw0003\talpha:1\talpha:2\t\t\t\tpraise\tneutral\t\tm1 m2\n")
PY
python3 "$SCRIPT_DIR/chat_check.py" "$TMP/run" "$TMP/outside.tsv" > "$TMP/ow.out" 2>&1
OW_RC=$?
if [ "$OW_RC" -eq 1 ] && grep -qi "outside window" "$TMP/ow.out"; then
  ok outside_window
else
  bad outside_window
fi

exit "$FAILED"
