# <ID>: <one-line title>

> Agent: <role> · Chain: <chain name>, part <k> of <n> · Base: <full commit hash> · Branch: <branch>
> Worktree: <absolute path> · Files: <1 to 3 paths> · Commit message: "<exact message>" (or `Commit: none`)

## Goal
<Two lines at most: what changes and why. No design left open.>

## Map and memory entries
<Only the entries this brief needs, for example "map/convex.md: queue.ts > callNext (line 210)".
Or "None".>

## Step 0: preflight
<First brief of a chain:>
`<cd> && git fetch origin && git ls-remote origin refs/heads/<branch>`
EXPECTED: nothing printed.
`<cd> && git worktree add -b <branch> <worktree> <base>`
`cd <worktree> && ln -s <shared node_modules> node_modules`
<Later briefs:>
`cd <worktree> && pwd && git branch --show-current && git rev-parse HEAD && git status --short`
EXPECTED:
```
<worktree>
<branch>
<previous audited commit>
```

## Step 1: <one change>
File: `<absolute path>`
Anchor: `<exact unique line>`
Change: <exact words; a small snippet only if it removes doubt>
Check: `<command>`
EXPECTED: `<exact output>`

<Steps 2 to 5 the same way. At most 6 steps in total.>

<Every brief that creates or rewrites a file, add this line unchanged:>
Writing files: at most 35 lines per write; a longer file is written in parts (first write, then
appends or edits). Read a file before you overwrite it. A write fails: retry once with half the text.
Never delete or rewrite a file to recover. Work only inside the worktree: never `cd` to /tmp or any
other folder. Your final message is the report only (P-002 lesson 2026-11-09; K-001, AG-001 2026-11-19).

## Step 6: checks, commit, push
`cd <worktree> && <PATH export> && npx tsc -b --force; echo "EXIT=$?"` EXPECTED: `EXIT=0`
`cd <worktree> && <PATH export> && npx eslint . 2>&1 | grep "problems"` EXPECTED: `<known line>`
`cd <worktree> && <PATH export> && npx vitest run <named files> 2>&1 | grep -E "^ +Tests "` EXPECTED: `<count>`
`cd <worktree> && git add <files> && git commit -m "<exact message>" && git push -u origin <branch> && git status --short`
EXPECTED: the commit line, the push lines, then nothing from `git status`.
Kilo asks the owner before the push; he approves it.

## Before you send it (the writer's checks, not the agent's)
- The run folder holds the law part, `_team.md`, the brain and this brief: Kilo reads nothing outside `--dir`.
- The model: `jl model worker <role>` (skips retired pairs).
- No `$` inside double-quoted shell strings; every name a test uses is imported in the brief.
- Machine checks run under `sh`: no `<( )`, no bash-only syntax (octopus step 8 lessons).

## Machine checks
The runner runs these itself after the session and ignores the report's word. One pair per check:
CHECK <command, run in the run folder>
PASS-IF <regex the output must match>
No pair = checks NONE = the run is never clean.

## Report
Use the report format in `_team.md` section 5. Under CHECKS, paste every check this brief lists, in
order: Step 0, each step's check, the checks, the commit. (Briefs 78 and 73b-fix2 left some out.)
