# Agent benchmarks

> v1.2 · 2026-11-06 · written by the Brain Creator. Since W-010 a replay tool for gate 4 (HANDBOOK
> section 8), no longer a gate. Status: built (briefs bench-1 to bench-5, S-25);
> first BASELINE 2026-10-24 (W-005).

Every change to the law's first part, `_team.md`, a brain or a template is measured before it ships.
The bench runs real Kilo sessions on fixed tasks in a throwaway repo, scores them with scripts, and
adds one row per task to `LOG.md`. It never touches a project's code or data: the repo it works in is
synthetic and is rebuilt for every run.

## Run
`agents/bench/run.sh <task | all>`. Each task runs 3 times, unattended, on the bench model
the first model `jl model worker` prints (or `MODEL=...`); compare only rows on the same model. Cost 0.
Each run builds a fresh repo in `/tmp/jl-bench/run` (`fixture/make.sh`), plants the task's commit if
it has a `setup.sh`, hires the agent with the hire command of `HANDBOOK.md` section 1, and scores the
result with the task's `score.sh`. `run.sh` prints one line per run (session id, scores, tokens,
minutes), then the new `LOG.md` rows, so the master wakes once per batch and reads a few lines. The
last batch's reports and score lines stay in `/tmp/jl-bench/results/`; transcripts stay in Kilo's
database.

## Files
| Path | Holds |
|---|---|
| `run.sh` | The runner and the bench model |
| `rules.sh` | Rule checks every scorer shares |
| `fixture/make.sh`, `fixture/card.md` | The synthetic project and its project card |
| `tasks/<task>/` | `brief.md` (what the agent gets), `score.sh` (hidden), `setup.sh` (optional) |

A brief or card uses `@REPO@`, `@BASE@` and `@HEAD@`; `run.sh` fills them in. A line
`@INCLUDE <task>` prints that task's brief (the Sniper audits the Engine's brief).

## Tasks (v1)
| Task | Role | What it tests |
|---|---|---|
| engine-01 | Engine | One server function: validators, auth helper, permission check, exact error |
| scribe-01 | Scribe | Five strings in English and Arabic; both key sets stay identical |
| sniper-01 | Sniper | A commit with four planted defects: finds them all and edits nothing |
| researcher-01 | Researcher | Four questions on a local fictional site (`setup.sh` serves it on 127.0.0.1:8799): facts cited, quotes on the pages (`tools/research_check.py`), an honest NOT FOUND |

## Scores (median of the 3 runs)
- **Work:** hidden checks passed. The agent never sees them.
- **Rules:** scope, banned patterns, exact commit message, clean status, report format with raw checks.
- **Tokens:** read from Kilo's session database (`~/.local/share/kilo/kilo.db`). **Minutes:** wall
  clock of the run.
- **Start-up words:** the law's first part + `_team.md` + the brain.

## Verdict, against the last BASELINE row of the same task
- **WORSE:** Work or Rules dropped. The change does not ship until it is fixed.
- **BETTER:** Work and Rules held or rose, and at least one of them rose, or tokens or minutes fell by
  10% or more.
- **SAME:** anything else.

Each change that ships sets a new BASELINE. Kilo's database records only `kilo-auto/free` for its
automatic router, not the model behind it, so the bench never uses the router. Changing the bench
model is a change of its own: it gets a new BASELINE first.
