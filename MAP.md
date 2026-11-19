# The Jamilabs agent company on one page

> v1.4 · 2026-11-19 · Brain Creator. The whole scheme in one read. Details live in the file each line names.
> Rule: a change to the scheme updates this page in the same commit (law 4).

## 1. What it is
An agent company that builds the owner's products cheaply and safely.
Claude sessions think and audit; free Kilo models do the work; programs do every check they can.
**Efficient** (law 15, LAW v1.9): quality at its highest, resources at their least. Each step goes to the
lowest tier that does it perfectly: a program, then Kilo, then Haiku (what Kilo cannot reach: browser,
Claude-only tools); a master only decides, briefs and audits. "No helicopter to the supermarket."
**Two pillars (planned, P-002 "Added 2026-11-10"):** the *swarm*: many tiny free agents on one task,
paid models only audit; the *input refinery*: cheap layers turn a long, contradictory request into a
clean brief before a master reads it (contradictions go back to the owner; raw text kept as a pointer).
Owner: the owner. He decides the product and gives every live go (H1).

## 2. The tiers (`agents/models.md`, law 18)
| Tier | Model | Started by | Job |
|---|---|---|---|
| `master` | Claude Opus / Sonnet | the owner opens it, says the role | decide, plan, brief, final audit |
| `sealed` | Claude Opus, pinned | a master, `claude -p` | Shield (security lead), law 25 |
| `checker` | Claude Haiku | a master, `claude -p --model haiku` in the background | audit, admit cards, Fix Lead |
| `worker` | free Kilo model (`jl model worker <role>`) | a master or checker, `kilo run` headless | one micro-brief: ≤3 files, ≤6 steps |

## 3. The network: who hires whom
```
the owner ─ go ─▶ master (Commander / director / Brain Creator)
                  │ writes brief  ─▶ worker (Kilo)  ─ report ─▶ Sniper (Kilo) ─▶ master audits for real
                  │ findings      ─▶ Fix Lead (checker) ─ hires ─▶ Kilo workers ─ proof ─▶ master
                  └ security work ─▶ Shield (sealed) ─ orders ─▶ Sec team
```
Departments (HANDBOOK §4 has the full chart, §11 the roster with one skill each):
Head office (Orchestrator, Brain Creator) · Projects (one Commander each) · Engineering (Eng Director,
Fix Lead, Test Auditor, Sniper, Lead, Engine-TS, Engine-PY, Painter, Wirer, Scribe, Tester-Server/Screen, Sweeper,
Mapper) · Security (Shield + 6) · Demolition (Demo-lead + 6) · R&D (Director, Researcher, Research Checker) · Marketing · Sales ·
Client Care. 45 roles, one brain file each in `agents/<role>.md`.

## 4. How agents talk
- **Hire:** one fresh session = one brief. One command prints law (executor part) + `_team.md` + brain
  + project card + brief (HANDBOOK §1). `jl <role>` does it for an open session.
- **Reports** are the agent's final message, never a file. Formats: `_team.md` §5 and each brain.
- **Carriers:** `tools/jl_runner.py run` saves each report as `report.md` in its run
  folder; Kilo's db is never opened (only `tools/kilo_watch.py` reads its metadata).
  `jl inbox [plan]` prints a plan's status lines, newest first (the bus, P-001 M1).
- **Watching:** `jl watch` shows every Kilo session: WORKING / QUIET / STUCK / FAILED / DONE.
- **Gates** (HANDBOOK §6): own checks → Sniper → Shield → Lead → master's real audit → the owner's go.

## 5. Knowledge: where it lives now
| Layer | File | Writer |
|---|---|---|
| Law, one page | `LAW.md` | Brain Creator + the owner's go |
| Why we decided | `wisdom/W-*.md` | Brain Creator |
| How the company works | `HANDBOOK.md` (long), this page (short) | Brain Creator |
| Brains | `agents/<role>.md`; ≤350 words for an executor, a master-type brain states its own cap | Brain Creator only |
| Lessons | `agents/memory/<role>.md` cards, `<role>.events.tsv` one line per attempt or strike | Commander proposes, checker admits |
| Plans | `plans/P-*.md` | Brain Creator with the owner |
| Per project | `<project>/.jamilabs/` card, memory, code map, run log | Commander |
| Shame | `memory/shame.md` (G2 breakers) | Brain Creator |

**Planned, not built:** P-001 (`plans/P-001-warehouse-and-bus.md`, PROPOSED): one fact per file +
SQLite index, role packs, an agent bus. "Programs search, models judge." Being rewritten as P-001 v2
after the P-002 research.

## 6. How it learns (HANDBOOK §8, laws 22-24)
Every attempt is logged → a passed task proposes a card → a checker admits it (PROBATION → PROVEN) →
`jl recipe` feeds proven cards into the next brief → 3 passes move it to a lower tier; 10 identical
runs become a script. 3 strikes in 10 runs retire a model from a role (`jl strikes`).

## 7. Tools
`jl` (roles, models, recipe, strikes, roads, watch) · `tools/kilo_watch.py` · `tools/research_check.py`
(opens every link, matches every quote) · `agents/bench/run.sh` (headless Kilo recipe) ·
`token-usage/` (Claude cost per session).
Web Deep Research (ChatGPT, Gemini) is a tool on trial: a Haiku session drives the owner's signed-in Chrome
(`jl-runs/P-002/trace-deep-research-browser.md`); T14 (finished, unreviewed) researched headless browsers to replace it.

## 8. Known weak points (seen, 2026-11-10)
1. Reports travel by hand or by db reads: no bus, no shared state.
2. Free Kilo models end runs without a final report (P-002 T01a) or step outside their folder and get
   killed (P-002 T06, T09); one Kilo at a time because of rate limits.
3. Most `events.tsv` files hold only a header: the learning loop has little data yet.
4. Orchestrator and Kilo Method B (one agent file per role) are written but not proven.
5. `HANDBOOK.md` is 3,180 words: too long for an efficient start-up; this page is the fix.
6. Browser work depends on one extension and per-site permissions (ChatGPT access was refused once);
   Deep Research quotas (ChatGPT rate limit, Gemini runs one-at-a-time) are unknown.
7. Swarm and refinery are ideas, not built or measured yet.
