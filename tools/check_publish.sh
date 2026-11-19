#!/usr/bin/env bash
set -u
TOOLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/tools"

run_case() {
    local case_num=$1
    local setup=$2
    local check=$3
    local expected_exit=$4

    T=$(mktemp -d)/r
    mkdir -p "$T"
    cd "$T"
    git init -q
    git config user.email "test@test"
    git config user.name "Test"

    eval "$setup"

    git add -A
    git commit -q -m "init"

    O=$(mktemp -d)/out
    mkdir -p "$O"

    python3 -I "$T/tools/publish.py" --dry "$O" >"$O.log" 2>&1
    local exit_code=$?

    if [[ $exit_code -ne $expected_exit ]]; then
        echo "FAIL case $case_num: exit $exit_code, expected $expected_exit"
        return 1
    fi

    eval "$check"
    local check_result=$?

    if [[ $check_result -ne 0 ]]; then
        echo "FAIL case $case_num: check failed"
        return 1
    fi

    echo "case $case_num ok"
    return 0
}

# Copy tools
copy_tools() {
    cp "$TOOLS_DIR"/leakcheck.py tools/
    cp "$TOOLS_DIR"/publish.py tools/
}

# Case 1: basic publish with swap
case1_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

case1_check() {
    [[ -f "$O/agents/a.md" ]] || return 1
    grep -q "made by the company" "$O/agents/a.md" || return 1
    [[ -f "$O/LICENSE" ]] || return 1
    tail -1 "$O.log" 2>/dev/null | grep -q "PUBLISH: 2 files to" || return 1
    return 0
}

# Case 2: excluded files not present
case2_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

case2_check() {
    [[ ! -f "$O/agents/memory/m.md" ]] || return 1
    [[ ! -d "$O/memory" ]] || return 1
    [[ ! -d "$O/tools" ]] || return 1
    return 0
}

# Case 3: jl executable
case3_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

case3_check() {
    [[ -x "$O/jl" ]] || return 1
    return 0
}

# Case 4: LICENSE content
case4_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

case4_check() {
    [[ -f "$O/LICENSE" ]] || return 1
    head -1 "$O/LICENSE" | grep -q "MIT License" || return 1
    grep -q "Copyright (c) 2026 Jamilabs" "$O/LICENSE" || return 1
    return 0
}

# Case 5: marker hit on new file
case5_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
    git add -A
    git commit -q -m "init"
    echo "Zork" > agents/b.md
    git add agents/b.md
    git commit -q -m "add b"
}

case5_check() {
    grep -q "agents/b.md:1: word:Zork" "$O.log" 2>/dev/null || return 1
    return 0
}

# Case 6: non-empty outdir
case6_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

case6_check() {
    # First run creates the outdir
    O2=$(mktemp -d)/out2
    mkdir -p "$O2"
    python3 -I "$T/tools/publish.py" --dry "$O2" >"$O2.log" 2>&1
    # Second run with same non-empty outdir
    python3 -I "$T/tools/publish.py" --dry "$O2" >"$O2.log2" 2>&1
    [[ $? -eq 2 ]] || return 1
    grep -q "publish: outdir is not empty" "$O2.log2" || return 1
    return 0
}

# Case 7: no --dry argument
case7_setup() {
    mkdir -p agents/memory tools memory
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    copy_tools
}

# Case 8: public/ overlay replaces manifest file
case8_setup() {
    mkdir -p agents/memory tools memory public
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "README.md" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    echo "mind readme" > README.md
    echo "public readme by Zork Corp" > public/README.md
    copy_tools
    git add -A
    git commit -q -m "init"
}

case8_check() {
    [[ $? -eq 0 ]] || return 1
    [[ -f "$O/README.md" ]] || return 1
    grep -q "public readme by the company" "$O/README.md" || return 1
    [[ ! -d "$O/public" ]] || return 1
    return 0
}

# Case 9: file count includes public overlay once
case9_setup() {
    mkdir -p agents/memory tools memory public
    echo "agents/*" > agency.manifest
    echo "jl" >> agency.manifest
    echo "README.md" >> agency.manifest
    echo "!agents/memory/*" >> agency.manifest
    echo "word:Zork" > memory/private-markers.txt
    echo "swap:Zork Corp=>the company" >> memory/private-markers.txt
    echo "made by Zork Corp" > agents/a.md
    echo "secret" > agents/memory/m.md
    echo '#!/bin/sh' > jl
    echo 'echo hi' >> jl
    chmod +x jl
    echo "mind readme" > README.md
    echo "public readme by Zork Corp" > public/README.md
    copy_tools
    git add -A
    git commit -q -m "init"
}

case9_check() {
    tail -1 "$O.log" 2>/dev/null | grep -q "PUBLISH: 3 files to" || return 1
    return 0
}

run_case7() {
    T=$(mktemp -d)/r
    mkdir -p "$T"
    cd "$T"
    git init -q
    git config user.email "test@test"
    git config user.name "Test"

    case7_setup

    git add -A
    git commit -q -m "init"

    O=$(mktemp -d)/out
    mkdir -p "$O"

    python3 -I "$T/tools/publish.py" "$O" >"$O.log" 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 2 ]]; then
        echo "FAIL case 7: exit $exit_code, expected 2"
        return 1
    fi

    grep -q "publish: only --dry exists" "$O.log" || return 1

    echo "case 7 ok"
    return 0
}

# Run all cases
all_passed=1

run_case 1 "$(declare -f case1_setup); case1_setup" "$(declare -f case1_check); case1_check" 0 || all_passed=0
run_case 2 "$(declare -f case2_setup); case2_setup" "$(declare -f case2_check); case2_check" 0 || all_passed=0
run_case 3 "$(declare -f case3_setup); case3_setup" "$(declare -f case3_check); case3_check" 0 || all_passed=0
run_case 4 "$(declare -f case4_setup); case4_setup" "$(declare -f case4_check); case4_check" 0 || all_passed=0
run_case 5 "$(declare -f case5_setup); case5_setup" "$(declare -f case5_check); case5_check" 1 || all_passed=0
run_case 6 "$(declare -f case6_setup); case6_setup" "$(declare -f case6_check); case6_check" 0 || all_passed=0
run_case 7 "$(declare -f case7_setup); case7_setup" "$(declare -f run_case7); run_case7" 0 || all_passed=0
run_case 8 "$(declare -f case8_setup); case8_setup" "$(declare -f case8_check); case8_check" 0 || all_passed=0
run_case 9 "$(declare -f case9_setup); case9_setup" "$(declare -f case9_check); case9_check" 0 || all_passed=0

if [[ $all_passed -eq 1 ]]; then
    echo "ALL 9 CASES PASSED"
    exit 0
else
    exit 1
fi