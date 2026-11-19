#!/usr/bin/env bash
# jl v1.14: print a role's start-up text, from any folder, for any model. HANDBOOK section 1.
# jl brain: the Brain Creator's brain (agents/brain-creator.md) then its handoff (open work).
# jl sec-brain: the Security Brain Creator, the sealed writer of the security team's brains (law 25).
# jl model <tier> [<role>]: today's model for a tier; with a role, skips models retired from it (law 24).
# jl recipe <role-stack/task-kind>: card pointers and the best card (LAW.md law 22, HANDBOOK section 8).
# jl strikes <role> <model>: strikes in that pair's last 10 runs (LAW.md law 24).
# jl roads <role> [events file]: identical passed routes; 10 or more = script candidate (LAW.md law 22).
# jl watch [args]: live monitor of Kilo sessions (tools/kilo_watch.py, brief W1).
# jl inbox <plan>: status lines of a plan's run folders (tools/inbox.py, plan P-001 M1).
# jl handoff read|write|highlights|import: one HANDOFF.md per project (tools/handoff.py, LAW.md law 16).
ROOT=$(dirname "$(readlink -f "$0")")

roles() {
  echo "Roles: brain $(ls "$ROOT/agents" | sed -n 's/\.md$//p' | grep -vE '^(_team|_judge|_demolition|models|brain-creator)$' | tr '\n' ' ')"
  echo "Use: jl <role>   Chat apps with no file access: jl paste <role>   Model for a tier: jl model master|checker|worker [<role>]"
  echo "     jl recipe <role-stack/task-kind>   jl strikes <role> <model>   jl roads <role>   jl watch [--title-prefix P] [--notify]"
}

if [ "$1" = model ]; then
  case "$2" in
    master) echo "Claude Opus (else Claude Sonnet)" ;;
    checker) echo "haiku" ;;
    worker)
      KILO=$(ls -d ~/.vscode/extensions/kilocode.kilo-code-*/bin/kilo 2>/dev/null | tail -1)
      HAVE=$(timeout 60 "$KILO" models 2>/dev/null)
      for M in $(awk '/^## `worker` list/{f=1} f&&/^```/{n++; next} f&&n==1{print}' "$ROOT/agents/models.md"); do
        echo "$HAVE" | grep -qxF "kilo/$M" || continue
        [ -n "$3" ] && "$ROOT/jl" strikes "$3" "$M" 2>/dev/null | grep -q '^RETIRE' && continue
        echo "$M"; exit 0
      done
      echo "No listed worker model is offered by Kilo today: bench a new one (agents/models.md)." >&2; exit 1 ;;
    *) echo "Use: jl model master|checker|worker [<role>]" >&2; exit 1 ;;
  esac
  exit 0
fi

if [ "$1" = recipe ]; then
  KEY=${2#*:}
  [ -z "$KEY" ] && { echo "Use: jl recipe <role-stack/task-kind>" >&2; exit 1; }
  PROJ=$(git rev-parse --show-toplevel 2>/dev/null)
  FILES=$(ls "$ROOT"/agents/memory/*.md 2>/dev/null)
  [ -n "$PROJ" ] && [ -f "$PROJ/.jamilabs/cards.md" ] && FILES="$FILES $PROJ/.jamilabs/cards.md"
  [ -z "$FILES" ] && { echo "NO CARD: $KEY. Novel task: full brief; its Closeout writes the first card."; exit 0; }
  LINES=$(awk -F'|' -v k="$KEY" '/^\| C-/ {f=$3; gsub(/ /,"",f); sub(/^[^:]*:/,"",f); if (f==k) print}' $FILES)
  [ -z "$LINES" ] && { echo "NO CARD: $KEY. Novel task: full brief; its Closeout writes the first card."; exit 0; }
  echo "$LINES"
  for S in PROVEN PROBATION; do
    BEST=$(echo "$LINES" | awk -F'|' -v s="$S" '{t=$8; gsub(/ /,"",t); i=$2; gsub(/ /,"",i); if (t==s) {print i; exit}}')
    [ -n "$BEST" ] && break
  done
  [ -z "$BEST" ] && { echo "No PROVEN or PROBATION card: treat as novel."; exit 0; }
  awk -v id="$BEST" 'FNR==1 && f {exit} $0=="### "id {f=1; print; next} f && /^### /{exit} f' $FILES
  exit 0
fi

if [ "$1" = strikes ]; then
  LOG=$ROOT/agents/memory/$2.events.tsv
  { [ -f "$LOG" ] && [ -n "$3" ]; } || { echo "Use: jl strikes <role> <model>" >&2; exit 1; }
  awk -F'\t' -v r="$2" -v m="$3" '
    NR>1 && $4==m { if (!($3 in seen)) { seen[$3]=1; order[++n]=$3 } kind[NR]=$5; brief[NR]=$3 }
    END {
      for (i=(n>10?n-9:1); i<=n; i++) last[order[i]]=1
      for (x in kind) if ((brief[x] in last) && kind[x] ~ /^(DEVIATION|RULE-BREAK|INVENTED|BENT-TEST)$/) { s++; if (kind[x]=="BENT-TEST") g=1 }
      printf "%s %s: %d strikes in the last %d runs\n", r, m, s, (n>10?10:n)
      if (g) print "RETIRE NOW (G2: bent test)"; else if (s>=3) print "RETIRE from this role (law 24)"; else print "OK"
    }' "$LOG"
  exit 0
fi

if [ "$1" = watch ]; then shift; exec python3 "$ROOT/tools/kilo_watch.py" "$@"; fi
if [ "$1" = handoff ]; then shift; exec python3 -I "$ROOT/tools/handoff.py" "$@"; fi
if [ "$1" = guard ]; then shift; exec python3 -I "$ROOT/tools/jl_guard.py" --once "$@"; fi  # disk and RAM guard (G-001)
if [ "$1" = inbox ]; then shift; exec python3 -I "$ROOT/tools/inbox.py" "$@"; fi

if [ "$1" = roads ]; then
  LOG=${3:-$ROOT/agents/memory/$2.events.tsv}
  { [ -n "$2" ] && [ -f "$LOG" ]; } || { echo "Use: jl roads <role> [events file]" >&2; exit 1; }
  python3 - "$LOG" <<'PY'
import re, sys
from collections import Counter
def norm(route):
    if re.fullmatch(r"C-[a-z0-9]+-\d+", route):
        return route
    out = []
    for cmd in route.split(";"):
        cmd = " ".join("<path>" if "/" in w else w for w in cmd.split())
        cmd = re.sub(r"\b\d{4}-\d{2}-\d{2}\b", "<date>", cmd)
        cmd = re.sub(r"\b[0-9a-f]{7,40}\b", "<id>", cmd)
        cmd = re.sub(r"\b\d+\b", "<n>", cmd)
        if cmd:
            out.append(cmd)
    return "; ".join(out)
c = Counter()
for i, line in enumerate(open(sys.argv[1], encoding="utf-8")):
    f = line.rstrip("\n").split("\t")
    if i == 0 or len(f) < 9 or f[4] != "ATTEMPT" or f[8].lower() not in ("yes", "ok", "1", "true", "pass"):
        continue
    c[norm(f[5])] += 1
if not c:
    print("No passed runs in " + sys.argv[1])
    sys.exit(0)
for r, n in c.most_common():
    print(f"{n}\t{r}")
for r, n in c.most_common():
    if n >= 10:
        print(f"SCRIPT CANDIDATE ({n} runs): {r}")
PY
  exit 0
fi

PASTE=
if [ "$1" = paste ]; then PASTE=1; shift; fi
ROLE=$(echo "$1" | tr 'A-Z' 'a-z')
[ -z "$ROLE" ] && { roles; exit 0; }
[ "$ROLE" = engine ] && ROLE=engine-ts  # old name (W-010)
[ "$ROLE" = brain-creator ] && ROLE=brain  # the brain and its handoff print together

# models.md: the Commander's brain is for Claude; any other model runs master-lite.
[ "$ROLE" = commander ] && [ -z "$CLAUDECODE" ] && ROLE=master-lite

EXTRA=
case "$ROLE" in
  brain) FILE=$ROOT/agents/brain-creator.md ;;  # open work: jl handoff read brain
  wise-man) FILE=$ROOT/agents/wise-man.md; EXTRA=$ROOT/agents/memory/wise-man/START.md ;;  # P-006 W3
  _team|_judge|_demolition|models) FILE= ;;
  *) FILE=$ROOT/agents/$ROLE.md ;;
esac
[ -f "$FILE" ] || { echo "No role '$1'."; roles; exit 1; }

case "$ROLE" in brain|leader|sec-brain|wise-man|data-analyst|commander|master-lite|marketing-manager|fix-lead|test-auditor|shield|sec-authz|sec-data|orchestrator|eng-director|rnd-director|sales-director|client-care|research-checker|content-checker|demo-lead) MASTER=1 ;; *) MASTER= ;; esac

if [ -n "$PASTE" ]; then
  if [ -n "$MASTER" ]; then cat "$ROOT/LAW.md"; else awk '/^## For masters/{exit} {print}' "$ROOT/LAW.md"; fi
fi
echo "Company files (LAW.md, HANDBOOK.md, agents/, templates/, wisdom/, memory/) are in $ROOT."
[ -z "$MASTER" ] && cat "$ROOT/agents/_team.md"
case "$ROLE" in demo-*) [ -z "$MASTER" ] && cat "$ROOT/agents/_demolition.md" ;; esac  # Demolition workers' shared rules
case "$ROLE" in shield|sec-*) ;; *) [ -n "$MASTER" ] && cat "$ROOT/agents/_judge.md" ;; esac
SHAME=$(grep '^| 2' "$ROOT/memory/shame.md" | tail -5)
[ -n "$SHAME" ] && printf 'Wall of Shame (G2), latest:\n%s\n' "$SHAME"
[ "$ROLE" = brain ] && [ -z "$CLAUDECODE" ] && echo "Not a Claude session: load and suggest only. Commit nothing to the law, wisdom or any brain."
cat "$FILE"
[ -n "$EXTRA" ] && cat "$EXTRA"
CARD=$(git rev-parse --show-toplevel 2>/dev/null)/.jamilabs/project-card.md
[ "$ROLE" != brain ] && [ -f "$CARD" ] && cat "$CARD"
exit 0
