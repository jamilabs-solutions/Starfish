#!/usr/bin/env bash
# run.sh v1.2. Runs the bench: each task RUNS times on the bench model, each run in a fresh synthetic repo; scores
# every run and adds one row per task (medians) to LOG.md. Usage: run.sh <task | all>
# Prints one line per run, then the new LOG.md rows. The last batch's reports and scores stay in
# /tmp/jl-bench/results/.
set -u
BENCH=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$BENCH/../.." && pwd)
KILO=${KILO:-$(ls -d ~/.vscode/extensions/kilocode.kilo-code-*/bin/kilo | tail -1)}
MODEL=${MODEL:-kilo/$("$(dirname "$(readlink -f "$0")")/../../jl" model worker)}
RUNS=${RUNS:-3}
RUN=/tmp/jl-bench/run
RESULTS=/tmp/jl-bench/results

if [ "${1:-}" = all ]; then TASKS=$(ls "$BENCH/tasks"); else TASKS=${1:?usage: run.sh <task | all>}; fi
for task in $TASKS; do [ -d "$BENCH/tasks/$task" ] || { echo "no such task: $task"; exit 1; }; done
rm -rf "$RESULTS" && mkdir -p "$RESULTS"

median() { printf '%s\n' "$@" | sort -n | sed -n "$((($# + 1) / 2))p"; }
version() { grep -m1 -oE 'v[0-9]+(\.[0-9]+)?' "$1"; }
fill() { sed -e "s|@REPO@|$RUN/repo|g" -e "s|@BASE@|$BASE|g" -e "s|@HEAD@|$HEAD|g"; }

CHANGE=$(git -C "$ROOT" rev-parse --short HEAD)
[ -n "$(git -C "$ROOT" status --porcelain -- LAW.md agents ':!agents/bench')" ] && CHANGE="$CHANGE+edits"

for task in $TASKS; do
  T=$BENCH/tasks/$task
  role=${task%%-*}; [ "$role" = engine ] && role=engine-ts  # Engine renamed (W-010)
  works=() rules=() tokens=() minutes=()
  for i in $(seq "$RUNS"); do
    rm -rf "$RUN" && mkdir -p "$RUN/hire"
    bash "$BENCH/fixture/make.sh" "$RUN" >/dev/null || exit 1
    BASE=$(git -C "$RUN/repo" rev-parse HEAD)
    if [ -f "$T/setup.sh" ]; then bash "$T/setup.sh" "$RUN/repo" >/dev/null || exit 1; fi
    HEAD=$(git -C "$RUN/repo" rev-parse HEAD)
    awk '/^## For masters/{exit} {print}' "$ROOT/LAW.md" > "$RUN/hire/law.md"
    cp "$ROOT/agents/_team.md" "$RUN/hire/team.md"
    cp "$ROOT/agents/$role.md" "$RUN/hire/brain.md"
    fill < "$BENCH/fixture/card.md" > "$RUN/hire/card.md"
    awk -v tasks="$BENCH/tasks" '/^@INCLUDE /{f = tasks "/" $2 "/brief.md"; while ((getline line < f) > 0) print line; next} {print}' \
      "$T/brief.md" | fill > "$RUN/hire/brief.md"
    words=$(cat "$RUN/hire/law.md" "$RUN/hire/team.md" "$RUN/hire/brain.md" | wc -w)
    prompt="You are the ${role^} agent of the Jamilabs team.
Run this one command. It prints, in order: the law's hard lines, team rules, your brain, the project
card, your brief. Read nothing else.
cat $RUN/hire/law.md $RUN/hire/team.md $RUN/hire/brain.md $RUN/hire/card.md $RUN/hire/brief.md
Then do the brief (the last file printed)."
    printf '%s\n' "$prompt" > "$RUN/hire/prompt.txt"
    python3 -I "$ROOT/tools/jl_runner.py" run --dir "$RUN" --workdir "$RUN" --brief-file "$RUN/hire/brief.md" \
      --prompt-file "$RUN/hire/prompt.txt" --plan bench --brief "$task-r$i" --role "$role" --model "${MODEL#kilo/}" \
      --vehicle kilo --timeout "${TIMEOUT:-1800}" > "$RUN/status.line"
    sid=$(cut -f14 "$RUN/status.line") minute=$(cut -f9 "$RUN/status.line")
    token=$(python3 -I "$ROOT/tools/kilo_watch.py" --tokens-of "$sid")
    cp "$RUN/report.md" "$RUN/report.txt"
    bash "$T/score.sh" "$RUN/repo" "$RUN/report.txt" "$BASE" "$HEAD" > "$RUN/score.txt" 2>&1
    w=$(grep -c '^WORK PASS' "$RUN/score.txt") wt=$(grep -c '^WORK ' "$RUN/score.txt")
    r=$(grep -c '^RULES PASS' "$RUN/score.txt") rt=$(grep -c '^RULES ' "$RUN/score.txt")
    cp "$RUN/report.txt" "$RESULTS/$task-r$i-report.txt"
    cp "$RUN/score.txt" "$RESULTS/$task-r$i-score.txt"
    echo "$task r$i $sid WORK $w/$wt RULES $r/$rt TOKENS $token MINUTES $minute" | tee -a "$RESULTS/runs.txt"
    works+=("$w") rules+=("$r") tokens+=("$token") minutes+=("$minute")
  done
  versions="$(version "$ROOT/LAW.md") / $(version "$ROOT/agents/_team.md") / $(version "$ROOT/agents/$role.md")"
  row="| $(date +%F) | $CHANGE | $task | ${MODEL#kilo/} | $versions | $(median "${works[@]}")/$wt"
  row="$row | $(median "${rules[@]}")/$rt | $(median "${tokens[@]}") | $(median "${minutes[@]}") | $words |  |"
  echo "$row" >> "$BENCH/LOG.md"
  echo "$row"
done