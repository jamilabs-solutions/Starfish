#!/usr/bin/env bash
set -u
KEEP_PY="$(cd "$(dirname "$0")/.." && pwd)/tools/keep.py"

T=$(mktemp -d)
export JL_KEEP_ROOT="$T/root"
export JL_KEEP_STATE="$T/state"

mkdir -p "$T/root/agents/memory"

seq 100 | tr '\n' ' ' > "$T/root/agents/a.md"
echo "one two three" > "$T/root/agents/small.md"
seq 30 | tr '\n' ' ' > "$T/root/LAW.md"
seq 50 | tr '\n' ' ' > "$T/root/notes.txt"

run_keep() {
    python3 -I "$KEEP_PY" "$@"
}

case_num=0
pass_case() {
    ((case_num++))
    echo "case $case_num ok"
}

fail_case() {
    ((case_num++))
    echo "FAIL case $case_num: $1"
    exit 1
}

run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "1: check on fixture should exit 0"
out=$(run_keep status)
[[ "$out" == "3 files kept, 0 restores" ]] || fail_case "1: status should print '3 files kept, 0 restores', got '$out'"
pass_case

echo "extra words here and there" >> "$T/root/agents/a.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "2: check after append should exit 0"
lines=$(wc -l < "$T/state/versions/agents__a.md.txt")
[[ $lines -eq 2 ]] || fail_case "2: versions file should have 2 lines, has $lines"
pass_case

python3 -c "open('$T/root/agents/a.md','w')"
out=$(run_keep check 2>&1)
[[ $? -eq 2 ]] || fail_case "3: check after emptying should exit 2, got $?"
[[ "$out" == *"KEEP: restored agents/a.md"* ]] || fail_case "3: stderr should start with restore message, got '$out'"
cmp -s "$T/root/agents/a.md" <(echo "extra words here and there" | cat - "$T/state/store/$(cat "$T/state/versions/agents__a.md.txt" | tail -1)") 2>/dev/null || {
    good_sha=$(tail -1 "$T/state/versions/agents__a.md.txt")
    cmp -s "$T/root/agents/a.md" "$T/state/store/$good_sha" || fail_case "3: a.md not restored to case-2 content"
}
qfiles=$(find "$T/state/quarantine" -type f | wc -l)
[[ $qfiles -eq 1 ]] || fail_case "3: quarantine should have 1 file, has $qfiles"
qfile=$(find "$T/state/quarantine" -type f)
[[ -s "$qfile" ]] && fail_case "3: quarantined file should be 0 bytes"
pass_case

awk '{for(i=1;i<=40;i++) printf "%s ", $i; print ""}' "$T/root/agents/a.md" > "$T/root/agents/a.md.tmp" && mv "$T/root/agents/a.md.tmp" "$T/root/agents/a.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 2 ]] || fail_case "4: check after cutting to 40 words should exit 2"
good_sha=$(tail -1 "$T/state/versions/agents__a.md.txt")
cmp -s "$T/root/agents/a.md" "$T/state/store/$good_sha" || fail_case "4: a.md not restored"
pass_case

awk '{for(i=1;i<=60;i++) printf "%s ", $i; print ""}' "$T/root/agents/a.md" > "$T/root/agents/a.md.tmp" && mv "$T/root/agents/a.md.tmp" "$T/root/agents/a.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "5: check after cutting to 60 words should exit 0"
w=$(wc -w < "$T/root/agents/a.md")
[[ $w -eq 60 ]] || fail_case "5: a.md should have 60 words, has $w"
pass_case

rm "$T/root/agents/a.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 2 ]] || fail_case "6: check after deleting a.md should exit 2"
[[ -f "$T/root/agents/a.md" ]] || fail_case "6: a.md should be restored"
w=$(wc -w < "$T/root/agents/a.md")
[[ $w -eq 60 ]] || fail_case "6: restored a.md should have 60 words, has $w"
pass_case

: > "$T/root/agents/small.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 2 ]] || fail_case "7: check after emptying small.md should exit 2"
content=$(cat "$T/root/agents/small.md")
[[ "$content" == "one two three" ]] || fail_case "7: small.md should be 'one two three', got '$content'"
pass_case

: > "$T/root/notes.txt"
run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "8: check after emptying notes.txt should exit 0"
[[ -s "$T/root/notes.txt" ]] && fail_case "8: notes.txt should stay empty"
pass_case

run_keep accept agents/a.md < /dev/null 2>&1 | grep -q "keep: accept needs a terminal"
[[ $? -eq 0 ]] || fail_case "9: accept without tty should exit 1 with message"
pass_case

: > "$T/root/LAW.md"
out=$(echo '{"tool_name":"Bash"}' | run_keep hook 2>&1)
[[ $? -eq 2 ]] || fail_case "10: hook after emptying LAW.md should exit 2, got $?"
[[ "$out" == *"KEEP: restored LAW.md"* ]] || fail_case "10: stderr should contain restore message, got '$out'"
pass_case

for i in {1..7}; do
    echo "word" >> "$T/root/agents/a.md"
    run_keep check >/dev/null 2>&1
done
lines=$(wc -l < "$T/state/versions/agents__a.md.txt")
[[ $lines -eq 5 ]] || fail_case "11: versions file should have 5 lines after 7 appends, has $lines"
pass_case

for i in $(seq 500); do
    seq 30 | tr '\n' ' ' > "$T/root/agents/memory/f$i"
done
run_keep check >/dev/null 2>&1
start=$(date +%s%N)
run_keep check >/dev/null 2>&1
end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))
[[ $elapsed -lt 500 ]] || fail_case "12: second check should be under 500ms, took ${elapsed}ms"
pass_case

out=$(run_keep status)
echo "$out" | grep -q "files kept, 5 restores"
[[ $? -eq 0 ]] || fail_case "13: status should show 5 restores, got '$out'"
pass_case

mkdir -p "$T/g"
cd "$T/g"
git init -q
git config user.email "test@test"
git config user.name "Test"
cp "$T/root/LAW.md" .
git add LAW.md
git commit -q -m "init"
: > LAW.md
git add LAW.md
JL_KEEP_ROOT="$T/g" run_keep precommit >/dev/null 2>&1
[[ $? -eq 1 ]] || fail_case "14: precommit should block empty LAW.md"
out=$(JL_KEEP_ROOT="$T/g" run_keep precommit 2>&1)
[[ "$out" == *"KEEP: commit blocked: LAW.md goes from 30 to 0 words."* ]] || fail_case "14: stderr should contain block message, got '$out'"
pass_case

git checkout HEAD -- LAW.md
echo "extra words here now" >> LAW.md
git add LAW.md
JL_KEEP_ROOT="$T/g" run_keep precommit >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "15: precommit should allow small addition"
pass_case

# 16: two levels deep is not protected
mkdir -p "$T/root/proj/sub"
printf '%*s' 30 | tr ' ' 'word ' > "$T/root/proj/sub/CLAUDE.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "16: check with two-level CLAUDE.md should exit 0"
: > "$T/root/proj/sub/CLAUDE.md"
run_keep check >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "16: check after emptying two-level CLAUDE.md should exit 0"
[[ -s "$T/root/proj/sub/CLAUDE.md" ]] && fail_case "16: two-level CLAUDE.md should stay empty"
pass_case

# 17: corrupt index.json
printf '{bad' > "$T/state/index.json"
out=$(run_keep check 2>&1)
[[ $? -eq 0 ]] || fail_case "17: check with corrupt index should exit 0, got $?"
[[ "$out" == *"keep: index.json was corrupt, rebuilt"* ]] || fail_case "17: stderr should contain rebuild message, got '$out'"
python3 -I -c "import json; json.load(open('$T/state/index.json'))" >/dev/null 2>&1
[[ $? -eq 0 ]] || fail_case "17: index.json should be valid JSON after rebuild"
pass_case

echo "ALL 17 CASES PASSED"