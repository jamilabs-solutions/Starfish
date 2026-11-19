# sniper-01: audit the commit for brief engine-01

> Agent: Sniper · Chain: bench, part 1 of 1 · Base: @BASE@ · Commit: @HEAD@ · Branch: main
> Worktree: @REPO@ · Files: none · Commit: none

## Goal
Audit the worker's commit `@HEAD@` against its brief, engine-01, printed below this brief. Report
every difference with its severity. Edit nothing.

## Step 0: preflight
`cd @REPO@ && git fetch origin && git rev-parse @HEAD@ && git log --oneline @BASE@..@HEAD@ && git status --short`
EXPECTED: the full hash `@HEAD@`, one commit line ending in `Add updatePatientPhone`, then nothing.

## Steps 1 to 6
Your brain's steps 2 to 7, with base `@BASE@` and commit `@HEAD@`. Every command starts with
`cd @REPO@ && `. The worker's worktree is `@REPO@`.
The brief's checks to re-run: `cd @REPO@ && node --test tests/ 2>&1 | grep -E "^# (pass|fail)"`

## Report
Use the report format in your brain, with `BRIEF: sniper-01`. Under CHECKS RE-RUN, paste every
command you ran and its raw output.

# The worker's brief

@INCLUDE engine-01