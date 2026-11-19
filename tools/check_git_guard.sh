#!/usr/bin/env bash
set -u

WORKTREE="~/workspace/jl-runs/K-002"
GUARD_ROOT="/r/jam"
PASS=0
FAIL=0

run_case() {
    local case_num=$1
    local tool=$2
    local cmd=$3
    local cwd=$4
    local want=$5

    local json
    json=$(python3 -I -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"command":sys.argv[2]},"cwd":sys.argv[3]}))' "$tool" "$cmd" "$cwd")

    local out
    out=$(echo "$json" | JL_GIT_GUARD_ROOT="$GUARD_ROOT" python3 -I "$WORKTREE/tools/git_guard.py" 2>&1)
    local got=$?

    if [[ $got -eq $want ]]; then
        echo "case $case_num ok"
        ((PASS++))
    else
        echo "FAIL case $case_num: want $want got $got"
        echo "  cmd: $cmd"
        echo "  cwd: $cwd"
        echo "  out: $out"
        ((FAIL++))
    fi
}

# Blocked cases (exit 2), cwd /r/jam unless named
run_case 1 "Bash" "git reset --hard HEAD~1" "/r/jam" 2
run_case 2 "Bash" "git reset -q --hard" "/r/jam" 2
run_case 3 "Bash" "git checkout -- ." "/r/jam" 2
run_case 4 "Bash" "git checkout ." "/r/jam" 2
run_case 5 "Bash" "git restore HANDBOOK.md" "/r/jam" 2
run_case 6 "Bash" "git clean -fd" "/r/jam" 2
run_case 7 "Bash" "git stash" "/r/jam" 2
run_case 8 "Bash" "git stash push -m x" "/r/jam" 2
run_case 9 "Bash" "cd /r/jam && git reset --hard" "/tmp" 2  # cmd contains ROOT via cd /r/jam && ...
run_case 10 "Bash" "git reset --hard" "/r/jam/agents" 2

# Allowed cases (exit 0)
run_case 11 "Bash" "git reset --soft HEAD~1" "/r/jam" 0
run_case 12 "Bash" "git status; git log --oneline -3" "/r/jam" 0
run_case 13 "Bash" "git reset --hard" "/r/jl-runs/K-002" 0
run_case 14 "Bash" "git stash list" "/r/jam" 0
run_case 15 "Bash" "git reset --hard" "/tmp/other" 0
run_case 16 "Read" "git reset --hard" "/r/jam" 0

# Check case 1 stderr starts with expected prefix
json=$(python3 -I -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"command":sys.argv[2]},"cwd":sys.argv[3]}))' "Bash" "git reset --hard HEAD~1" "/r/jam")
out=$(echo "$json" | JL_GIT_GUARD_ROOT="$GUARD_ROOT" python3 -I "$WORKTREE/tools/git_guard.py" 2>&1)
if [[ $out == GIT\ GUARD:\ blocked* ]]; then
    echo "case 1 stderr ok"
else
    echo "FAIL case 1 stderr: does not start with expected prefix"
    echo "  got: $out"
    ((FAIL++))
fi

run_case 17 "Bash" "git restore --staged x.md" "/r/jam" 0
# 18, 19: real folders: a sub-repo inside the root is its own tree; the root itself is shared
RT=$(mktemp -d); git init -q "$RT"; git init -q "$RT/sub"
SAVED_ROOT=$GUARD_ROOT; GUARD_ROOT=$RT
run_case 18 "Bash" "git reset --hard" "$RT/sub" 0
run_case 19 "Bash" "git reset --hard" "$RT" 2
GUARD_ROOT=$SAVED_ROOT

if [[ $FAIL -eq 0 ]]; then
    echo "ALL 19 CASES PASSED"
    exit 0
else
    exit 1
fi