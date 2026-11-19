#!/usr/bin/env bash
# Check for tools/locks/bash_gate.py (P-004 M2). Written by the master before the hire.
# Each case: expected exit (0 = allowed, 2 = blocked) and a Bash command fed as hook JSON.
set -u
cd "$(dirname "$0")/.."
G=tools/locks/bash_gate.py
P=0; F=0
case_() {
  want=$1; cmd=$2
  json=$(python3 -I -c 'import json,sys; print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$cmd")
  printf '%s' "$json" | python3 -I "$G" >/dev/null 2>/tmp/bash_gate_err; got=$?
  if [ "$got" = "$want" ]; then P=$((P+1)); else F=$((F+1)); echo "FAIL want $want got $got: $cmd"; fi
  if [ "$got" = 2 ] && ! [ -s /tmp/bash_gate_err ]; then F=$((F+1)); echo "FAIL blocked with empty stderr: $cmd"; fi
}
# allowed
case_ 0 'ls -la agents'
case_ 0 'cat LAW.md | head -20'
case_ 0 'grep -n leader agents/leader.md && wc -w agents/leader.md'
case_ 0 'jl handoff read brain'
case_ 0 'git status --short; git log --oneline -5'
case_ 0 'git diff main..sec/P-003 2>/dev/null'
case_ 0 'git commit -m "x: y"'
case_ 0 'cd /tmp && ls'
case_ 0 'python3 -I tools/jl_runner.py finish --dir x'
case_ 0 'bash tools/check_sec_score.sh'
case_ 0 'sha256sum sandbox/web/app-1/app.py >/dev/null 2>&1'
case_ 0 '/home/u/.vscode/extensions/kilocode.kilo-code-1.2/bin/kilo run --dir x "brief"'
case_ 0 'npm test'
# blocked: writes
case_ 2 'echo hi > app.py'
case_ 2 'cat a >> b'
case_ 2 'ls | tee out.txt'
case_ 2 'sed -i s/a/b/ app.py'
case_ 2 'sed s/a/b/ app.py'
case_ 2 "awk '{print}' a"
case_ 2 'cp a b'
case_ 2 'mv a b'
case_ 2 'rm -rf x'
case_ 2 'touch x'
case_ 2 'chmod +x x'
case_ 2 'find . -name x -delete'
case_ 2 "python3 -c 'open(\"a\",\"w\").write(\"x\")'"
case_ 2 'python3 evil.py'
case_ 2 'bash evil.sh'
case_ 2 "bash -c 'echo x'"
case_ 2 'perl -pi -e s/a/b/ f'
case_ 2 'git apply p.diff'
case_ 2 'git checkout -- app.py'
case_ 2 'git diff --output=f'
case_ 2 'cat <<EOF'
case_ 2 'ls $(rm x)'
case_ 2 'ls `rm x`'
case_ 2 'FOO=1 ls'
case_ 2 'dd if=a of=b'
case_ 2 'ls && rm x'
case_ 2 'ls || rm x'
case_ 2 'ls; rm x'
case_ 2 'ls & rm x'
case_ 2 'node -e 1'
case_ 2 ''
# blocked: writes and command runs hidden in allowed programs (audit round 1)
case_ 2 'cat <(rm x)'
case_ 2 'sort -o out a'
case_ 2 'sort --output=out a'
case_ 2 'uniq a b'
case_ 2 'rg --pre rm x'
case_ 2 'file -C -m x'
case_ 2 'git fetch --upload-pack=rm x'
case_ 2 'git push --receive-pack=x origin'
case_ 2 'sort a | head -5'
case_ 2 'sort -uo out a'
# bad input: blocked, never crashes open
printf 'not json' | python3 -I "$G" >/dev/null 2>&1; got=$?
if [ "$got" = 2 ]; then P=$((P+1)); else F=$((F+1)); echo "FAIL bad json got $got"; fi
echo "PASS $P FAIL $F"
[ "$F" = 0 ]
