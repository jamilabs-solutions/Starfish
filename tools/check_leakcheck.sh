#!/usr/bin/env bash
set -u

WORKTREE="$(cd "$(dirname "$0")/.." && pwd)"
LEAKCHECK="${WORKTREE}/tools/leakcheck.py"

run_case() {
    local case_num=$1
    local setup_cmd=$2
    local check_cmd=$3
    local expected_exit=$4
    local expected_output=$5

    T=$(mktemp -d)
    cd "$T"
    git init -q
    git config user.name "Test"
    git config user.email "test@test.com"

    cat > agency.manifest <<'EOF'
agents/*
LAW.md
!agents/memory/*
EOF

    mkdir -p memory
    cat > memory/private-markers.txt <<'EOF'
# comment
word:Zork
re:/home/[a-z]+/
EOF

    eval "$setup_cmd"

    output=$(python3 -I "$LEAKCHECK" $check_cmd 2>&1)
    exit_code=$?

    if [[ $exit_code -ne $expected_exit ]]; then
        echo "FAIL case $case_num: exit $exit_code (expected $expected_exit)"
        echo "$output"
        return 1
    fi

    if [[ -n "$expected_output" ]]; then
        if ! echo "$output" | grep -qF "$expected_output"; then
            echo "FAIL case $case_num: missing expected output '$expected_output'"
            echo "$output"
            return 1
        fi
    fi

    echo "case $case_num ok"
    return 0
}

# Case 1: clean file
run_case 1 \
    'mkdir -p agents && echo "hello world" > agents/a.md && git add agents/a.md && git commit -m "init"' \
    '--manifest' \
    0 \
    "LEAKCHECK: 0 hits in 0 of 1 files" || exit 1

# Case 2: word marker found
run_case 2 \
    'mkdir -p agents && echo -e "hello\nask zork today" > agents/a.md && git add agents/a.md && git commit -m "init"' \
    '--manifest' \
    1 \
    "agents/a.md:2: word:Zork" || exit 1

# Case 3: whole word only (zorkish should not match Zork)
run_case 3 \
    'mkdir -p agents && echo "zorkish thing" > agents/a.md && git add agents/a.md && git commit -m "init"' \
    '--manifest' \
    0 \
    "LEAKCHECK: 0 hits in 0 of 1 files" || exit 1

# Case 4: excluded by ! pattern
run_case 4 \
    'mkdir -p agents/memory && echo "Zork" > agents/memory/x.md && git add agents/memory/x.md && git commit -m "init"' \
    '--manifest' \
    0 \
    "" || exit 1

# Case 5: not public
run_case 5 \
    'mkdir -p clinic && echo "Zork" > clinic/notes.md && git add clinic/notes.md && git commit -m "init"' \
    '--manifest' \
    0 \
    "" || exit 1

# Case 6: regex marker
run_case 6 \
    'echo "see /home/bob/x" > LAW.md && git add LAW.md && git commit -m "init"' \
    '--manifest' \
    1 \
    "LAW.md:1: re:/home/[a-z]+/" || exit 1

# Case 7: --staged reads staged copy, new leak detected
run_case 7 \
    'mkdir -p agents && echo "clean" > agents/a.md && git add agents/a.md && git commit -m "init" && echo "Zork" > agents/a.md && git add agents/a.md' \
    '--staged' \
    1 \
    "agents/a.md:1: word:Zork" || exit 1

# Case 8: --staged with only non-public file staged
run_case 8 \
    'mkdir -p clinic && echo "Zork" > clinic/n.md && git add clinic/n.md' \
    '--staged' \
    0 \
    "" || exit 1

# Case 9: path mode
run_case 9 \
    'mkdir -p clinic && echo "Zork" > clinic/n.md' \
    'clinic/n.md' \
    1 \
    "clinic/n.md:1: word:Zork" || exit 1

# Case 10: markers file removed
run_case 10 \
    'mkdir -p agents && echo "hello" > agents/a.md && git add agents/a.md && git commit -m "init" && rm memory/private-markers.txt' \
    '--manifest' \
    2 \
    "leakcheck: no markers file" || exit 1

# Case 11: commit has Zork, append line without new marker, staged should pass
run_case 11 \
    'mkdir -p agents && echo "Zork here" > agents/a.md && git add agents/a.md && git commit -m "init" && echo "more text" >> agents/a.md && git add agents/a.md' \
    '--staged' \
    0 \
    "agents/a.md:1: word:Zork" || exit 1

# Case 12: commit has 2 markers, staged has 3 (one new)
run_case 12 \
    'mkdir -p agents && echo "Zork /home/bob/x" > agents/a.md && git add agents/a.md && git commit -m "init" && echo "Zork /home/bob/x zork" > agents/a.md && git add agents/a.md' \
    '--staged' \
    1 \
    "NEW: agents/a.md has 3 markers, HEAD had 2." || exit 1

# Case 13: the gate integration test
T=$(mktemp -d)
cd "$T"
git init -q
git config user.name "Test"
git config user.email "test@test.com"
mkdir -p tools
cp "$WORKTREE/tools/keep.py" tools/
cp "$WORKTREE/tools/leakcheck.py" tools/
cp "$WORKTREE/tools/precommit.sh" tools/
mkdir -p agents
mkdir -p memory
cat > agency.manifest <<'EOF'
agents/*
LAW.md
!agents/memory/*
EOF
cat > memory/private-markers.txt <<'EOF'
# comment
word:Zork
re:/home/[a-z]+/
EOF
git add . && git commit -m "init" --no-verify
ln -s ../../tools/precommit.sh .git/hooks/pre-commit
echo "Zork" > agents/b.md
git add agents/b.md
output=$(git commit -m x 2>&1)
exit_code=$?
if [[ $exit_code -ne 1 ]]; then
    echo "FAIL case 13: exit $exit_code (expected 1)"
    echo "$output"
    exit 1
fi
if ! echo "$output" | grep -qF "NEW: agents/b.md"; then
    echo "FAIL case 13: missing expected output 'NEW: agents/b.md'"
    echo "$output"
    exit 1
fi
echo "case 13 ok"

# Case 13b: commit succeeds after fixing
echo "hello" > agents/b.md
git add agents/b.md
output=$(git commit -m y 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    echo "FAIL case 13b: exit $exit_code (expected 0)"
    echo "$output"
    exit 1
fi
echo "case 13b ok"

# Case 14: swap line removes marker before scan
run_case 14 \
    'mkdir -p agents && echo "ask Zork Corp now" > agents/a.md && cat >> memory/private-markers.txt <<EOF
swap:Zork Corp=>the company
allow:agents/bench/* word:Zork
EOF
git add . && git commit -m "init"' \
    '--manifest' \
    0 \
    "LEAKCHECK: 0 hits in 0 of 1 files" || exit 1

# Case 15: allow line filters hits by path pattern
run_case 15 \
    'mkdir -p agents/bench agents && echo "Zork" > agents/bench/x.md && echo "Zork" > agents/y.md && cat >> memory/private-markers.txt <<EOF
swap:Zork Corp=>the company
allow:agents/bench/* word:Zork
EOF
git add . && git commit -m "init"' \
    '--manifest' \
    1 \
    "agents/y.md:1: word:Zork" || exit 1

# Case 16: swap + allow in staged mode
run_case 16 \
    'mkdir -p agents && echo "hello" > agents/a.md && git add agents/a.md && git commit -m "init" && echo "Zork Corp" > agents/a.md && cat >> memory/private-markers.txt <<EOF
swap:Zork Corp=>the company
allow:agents/bench/* word:Zork
EOF
git add agents/a.md' \
    '--staged' \
    0 \
    "" || exit 1

echo "ALL 16 CASES PASSED"