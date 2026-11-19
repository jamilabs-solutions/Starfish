# The Jamilabs Agent Handbook

> v2.9 · 2026-11-19 · written by the Brain Creator. How the agent company works. Shared by every project.
> The short version is `MAP.md` (one page); keep both true in the same commit.

## 1. How to hire an agent
One agent = one fresh Kilo session = one brief. Paste:

```
You are the <role> agent of the Jamilabs team.
Run this one command. It prints, in order: the law's hard lines, team rules, your brain, the project
card, your brief. Read nothing else.
<one command, joined with &&: awk '/^## For masters/{exit} {print}' <root>/LAW.md, then cat the
two agent files, then print the card and the brief>
Then do the brief (the last file printed).
```

One command instead of five reads: every tool call re-sends the agent's whole context, so five reads
cost five times the start-up. The `awk` prints the law only up to its master part (W-004). When a file lives only on a branch, print it with
`git -C <repo> show <branch>:<path>`. The project card gives the exact command.

Auditors get one more line: `The worker's report is below:` followed by the pasted report.
The Lead gets the worker's report and the auditor's report the same way.
The code map and the project memory are never read whole. The brief names the exact entries.

**Which model (law 18, `agents/models.md`):** a brain names its tier, never a model. A `worker` runs as
`kilo run --model kilo/$(jl model worker <role>) ...`; it prints the best listed model Kilo offers today
that is not retired from that role (law 24). Kilo reads nothing outside `--dir`: copy the law part,
`_team.md`, the brain and the brief into the run folder and print them from there. Shield runs on Opus (law 25). A `checker` (Test Auditor, Fix Lead) runs as a headless Haiku session started by
a master in the background: `claude -p "You are the <role> of the Jamilabs team. Run jl <role> and
follow it. <task, files, findings>" --model haiku --allowedTools "Bash Read Edit Write Grep Glob" < /dev/null`
(prompt first; proven 2026-11-06).

**Locks (P-004 M2):** `--allowedTools` is no lock: his settings run in `bypassPermissions`. A post that
must not edit starts with `--tools "<list>"` (only those tools exist), or with
`--settings <root>/tools/locks/door.json` (no Edit, Write or NotebookEdit; Bash only through
`tools/locks/bash_gate.py`, which passes reading, `jl`, `kilo run`, git and the listed test
commands; check: `bash tools/check_bash_gate.sh`). A door the owner opens is a folder under `doors/`
whose `.claude/settings.json` links to that file.

**A session you open yourself, any folder, any model:** say its role ("you are the commander"). It runs
`jl <role>` (law 19), which prints the brain and the card of the repo it is in; `jl` alone lists the
roles. A chat app with no file access: run `jl paste <role>` yourself and paste the output. The law
reaches sessions by itself: Claude Code imports it in `~/.claude/CLAUDE.md`; Kilo loads
`~/.config/kilo/AGENTS.md`, a link to `LAW.md`. A new CLI gets one more such link.

## 2. Knowledge layers
Every agent starts from files, never from exploring the code.

| Layer | Lives in | Holds | Written by | Read by |
|---|---|---|---|---|
| Law | `LAW.md` | Hard lines and laws | Brain Creator, with the owner's go | Masters: all. Executors: the part above "For masters" |
| Book of Wisdom | `wisdom/` | Strategic decisions and the sources behind them | Brain Creator | Masters, before reopening a decision |
| Brain Creator handoff | seat `brain` of `HANDOFF.md` | Threads, now, next; `jl handoff read brain` | Brain Creator | A session becoming the Brain Creator |
| Brain session history | `wisdom/brain-sessions.md` | What past brain sessions measured and learned | Brain Creator | The Brain Creator, when a past run matters |
| Playbook | `PLAYBOOK.md` | The Jamilabs way | Brain Creator, with the owner | Commander |
| Master memory | `memory/decisions.md` | the owner's big decisions, all projects | Brain Creator | Commander |
| Handbook | `HANDBOOK.md` | How the agent company works | Brain Creator | Commander |
| Team rules | `agents/_team.md` | How every executor meets the law | Brain Creator only | Every executor |
| Agent brains | `agents/<role>.md` | One role's instructions, skills and lessons | Brain Creator only | That agent |
| Brain memory | `agents/memory/<role>.md` | Scope, FIX ASAP flag, company cards (pointers + cards) | Commander proposes, `checker` admits; Shield: the `sealed` writer with the owner's go | `jl recipe` only |
| Brain events | `agents/memory/<role>.events.tsv` | One line per attempt or strike | Commander, appends only | Brain Creator weekly; `jl strikes` |
| Project cards | `<project>/.jamilabs/cards.md` | Cards true only in that project | Commander proposes, `checker` admits | `jl recipe` only |
| Templates | `templates/` | Brief, research brief, run log, run trace, project card, project memory | Brain Creator | Commander |
| Project card | `<project>/.jamilabs/project-card.md` | Paths, commands, restrictions, conventions | Commander | Every agent in the project |
| Project memory | `<project>/.jamilabs/memory.md` | Project decisions and known facts | Commander | Commander; agents only where the brief points |
| Code map | `<project>/.jamilabs/map/` | File, line, kind, name of every export | Mapper builds, Commander keeps | Agents only where the brief points |
| Briefs | the folder the project card names | One task for one agent | Commander | One agent |
| Run log | `<project>/.jamilabs/runs/LOG.md` | One row per brief: date, plan step, commit, result, deviations | Commander | Commander, Brain Creator |
| Run traces | `<project>/.jamilabs/runs/` | Reports, findings, lessons | Commander | Brain Creator |

A project's own constitution, if it has one, wins for that project, except the law's hard lines,
which hold in every project. Any conflict goes to the owner.

## 3. The Brain Creator
- One Claude session on Opus, continued through handovers. No other session and no other model
  creates or changes the law, the Book of Wisdom, the playbook, this handbook, `_team.md`, the
  templates or any agent brain.
- A new session becomes the Brain Creator with `jl brain`: the post's brain
  (`agents/brain-creator.md`, stable, with the method for writing a brain) and then
  `jl handoff read brain` (the seat's open work). It rewrites that seat at the end of every session.
- Other sessions (Commanders, other models) may suggest a change. Only the Brain Creator writes it.
- Every mistake gets two fixes: the code fix, in a new session; and the real fix, in the brain of the
  agent that made it, so it never repeats.
- Every brain change is checked against every existing rule first. A conflict goes to the owner.

## 4. The map: JamiLabs Agents (W-009)

Tiers are the model a role needs: `master` = Opus or Sonnet, `checker` = Haiku or better, `worker` =
a free Kilo model on trial under the audit (`jl model <tier>`); `sealed` = Opus, pinned by the owner (Shield).

```
OWNER         the owner: decides the product; approves anything live or paid

HEAD OFFICE
  Orchestrator      master   sees every project, turns plans into orders, accepts only proof
  Brain Creator     master   writes the law and every brain

PROJECTS      one PM per project (Commander, master): idea -> plan -> proven product;
              borrows people from every department below

ENGINEERING   head: Eng Director (master): one way of building, audits each milestone
  Fix Lead          checker  turns audit findings into tiny briefs, proves every fix
  Test Auditor      checker  finds every break no test catches, spots bent tests
  Sniper            worker   every line vs the brief; faster? best algorithm? better structure?
  Lead              worker   confirms findings, designs the fix
  Engine-TS         worker   TypeScript server code: correct first, then the best-fitting algorithm
  Engine-PY         worker   Python modules and their tests, exactly from the brief
  Painter           worker   screen look, exactly from the spec
  Wirer             worker   connects screens to the server
  Scribe            worker   exact text, every language
  Tester-Server     worker   server tests, as a user and as an attacker; proves each can fail
  Tester-Screen     worker   screen tests, same way
  Sweeper           worker   cleanup, version bumps
  Mapper            worker   keeps the code map

SECURITY      head: Shield, the Security Lead (sealed, Opus): threat model, orders, re-checks, verdict;
              rules only with the owner's go (law 25); serves every project through its target card
  Sec-authz         checker  access holes: who calls, may they, data scope, abuse
  Sec-data          checker  inputs, leaks, output, randomness, secrets, dependencies
  Sec-tools         worker   Semgrep, gitleaks, osv-scanner, npm audit: raw output
  Sec-redteam       worker   one exploit test per finding, sandbox only
  Sec-fixer         worker   closes one proven hole until its exploit test passes
  Sec-keeper        worker   permanent test + proposed Semgrep rule per fixed hole
  Intel Scout       worker   the Researcher, weekly: CVEs in our deps, the local data protection law

DEMOLITION    head: Demo-lead (checker): briefs from the target card, re-runs every break, routes it;
              sandbox with fake data only; a break counts only with a failing repro; never fixes (W-011)
  Demo-fuzzer       worker   one input field at a time, values it was not built for
  Demo-chaos        worker   user flows out of order
  Demo-racer        worker   the same action at the same moment; local load
  Demo-intruder     worker   the attack list of the target's kind
  Demo-time         worker   midnight, month ends, time zones, daylight saving
  Demo-recorder     worker   smallest repro and one failing test per kept break

R&D           head: R&D Director (master): new features, new studies, new free models
  Researcher        worker   every fact with a link and an exact quote
  Research Checker  checker  opens every link, matches every quote

MARKETING     head: Marketing Manager (master): positioning, messaging, allowed claims
  Copywriter        worker   drafts only from given facts, never invents
  Social Drafter    worker   one post per network, within its limit
  Content Checker   checker  every published word true and allowed

SALES         head: Sales Director (master): buyers, offers, pipeline; drafts only, the owner sends
  uses Copywriter, Researcher, Content Checker

CLIENT CARE   head: Client Care (master): every live client watched, every bug closed with proof
  Log Reader        worker   groups errors from logs, no personal data
  bugs go to Engineering's Fix Lead
```

**The audit loop.** An Opus session audits (code, security, tests) and writes a findings file. A Fix
Lead takes it: confirms, splits, briefs workers, proves each fix (G1), reports. The Opus session
audits again. Repeat until the audit finds nothing.

| Level | Edits code? | Reports to |
|---|---|---|
| Owner | No | |
| Manage | Never; only plans, briefs, brains | the owner (directors and PMs through the Orchestrator once it exists) |
| Check | Never; briefs and checks only | The master that hired it |
| Work | Only the files in their brief | The checker or master that hired it |

## 5. The life of a task
1. the owner brings an idea. The PM follows the flow (law 20): checks it against best practice, brings
   findings and suggestions, keeps a list of every point, agrees a plan with the owner. His approval
   is the go for the whole plan (G3): the PM runs it to the end without asking again.
2. The Commander splits the work into micro-briefs: one role, at most 3 files, 6 steps, about 15 minutes.
3. For each micro-brief, the Commander runs the worker and then the Sniper as Kilo sessions itself.
   For security work (auth, permissions, personal data, secrets, payments, uploads) it adds Shield,
   the Security Lead (`sealed`, Opus, law 25), who runs the security team (section 4).
   A research brief has no Sniper: the Commander audits its sources (`commander.md`).
4. The worker runs in a fresh session and ends with its report.
5. The Commander pastes that report into the Sniper's hire prompt, in another fresh session.
6. Sniper says CLEAN: next step. Sniper reports findings: they go to a Fix Lead (section 4, the
   audit loop), or, for one small finding, to a Lead and then a fix brief.
7. The Commander audits for real: the diff against the spec, the full suite, CI. Never a report's word.
8. Passed: the next micro-brief. Failed: a fix brief for a NEW worker session, and the lesson goes
   into a run trace for the Brain Creator.
9. The Commander assembles audited branches and prepares the release.
10. Live actions: each named in the approved plan (H1), or one go each from the owner.
11. A step is done only when its check passed and its output is shown (G1). A bent test is G2.

The Commander never waits open (laws 16, 17). Before a wait of 50 minutes or more with over 100k
context, at 200k, or at the end of the day, it writes a resume pack to `.jamilabs/runs/RESUME.md`
(`token-usage/tools/make_resume_pack.sh` prints the next step, git state and the last run-log rows;
it adds the open findings; at most 1,500 words) and ends. A new
Commander session starts from the pack and the project card.

## 6. Gates

| Gate | Who | Passes when | On fail |
|---|---|---|---|
| 1. Own checks | Worker | Every check in the brief prints its expected output | Stop and report |
| 2. Code audit | Sniper | The diff matches the brief exactly, nothing more, nothing less | Findings to the Lead |
| 3. Security audit | Shield and its team (security work only) | No finding above LOW, each re-checked by Shield | Findings to the Lead |
| 4. Verdict | Lead (only when there are findings) | Every finding confirmed or dismissed with evidence | Fix design and lesson to the Commander |
| 5. Real audit | Commander | Spec, full suite and CI all pass | Fix brief and run trace |
| 6. Go | the owner | Explicit approval | Nothing moves |

## 7. Reports between agents
| From | To | Format in |
|---|---|---|
| Worker | Sniper, Shield, Commander | `_team.md` section 5 |
| Sniper | Lead or Commander | `sniper.md`, "Your report" |
| Shield | Lead or Commander | `shield.md`, "Your report" |
| Lead | Commander | `lead.md`, "Your report" |
| Commander | Brain Creator | the run trace (`templates/run-trace.md`) |

Reports are final messages, never files; the runner saves each as `report.md` in its run
folder, and Kilo's db is never opened (P-001 M1).

## 8. The training loop (W-010)
Quality comes from the pipeline; the brain learns from memory. Laws 22 to 25.

1. **Log.** Every brief gets a run-log row (`templates/run-log.md`), and every attempt gets a line in
   the brain's events file, tab-separated: `date project brief model kind route min tokens ok note`.
   Kinds: `ATTEMPT`, and the strikes `DEVIATION`, `RULE-BREAK`, `INVENTED`, `BENT-TEST`.
2. **Closeout** (after Complete). The Commander proposes a card (`templates/card.md`): try first,
   never. It picks the class with the test "true in a new, empty repo with the same stack?" and
   writes the pointer line as PROPOSED.
3. **Admit a card:** a `checker` checks scope (the memory file's Scope), hard lines and source (an
   audited run, the commit exists), then sets PROBATION. 3 clean uses: PROVEN. A failed use: REVIEW.
4. **Use a card:** before a brief, the Commander runs `jl recipe <role-stack/task-kind>` and compiles
   the hit into the brief's steps (law 9). The audit is never skipped on a hit.
5. **Known road:** the same card PROVEN with 3 passes in a row moves to the lowest tier that passes; 10 runs
   with the same commands once values are stripped (paths, ids, branches, dates) become a script
   candidate (`jl roads <role>` counts them): a Kilo brief builds it, the master proves it.
6. **Brain changes** (weekly, or at once on `FIX ASAP: <reason>, events <ids>` at the top of the
   memory file, set by the Commander). The Brain Creator reads the events and traces, then passes all
   seven gates: scope, hard lines, source, proof (replay the source task with and without the change,
   plus one in-scope task, on the bench runner; fewer attempts or tokens and nothing worse), probation,
   one writer, rollback (git; revert the brain and quarantine everything that source added since).
   Trace causes still decide where a lesson goes: BRIEF GAP to `commander.md`, BRAIN GAP or AGENT SLIP
   to the brain, MISCOMMUNICATION to a report format. At a cap, a new rule replaces an old one.
7. **Strikes:** `jl strikes <role> <model>` after every run with a strike. 3 in the pair's last 10
   runs: remove the model from that role in `agents/models.md`; `BENT-TEST` retires at once (G2,
   `memory/shame.md`).
8. **Security is sealed** (law 25): only the `sealed` Security Brain Creator (`jl sec-brain`) writes the security team's brains and memory. Each rule goes to the owner as
   a plain card (what it protects, the attack in one sentence, the three proofs, the cost) and enters
   only with his go.

## 9. Kilo setup
- **Method A, works now:** paste the hire prompt (section 1) into a fresh Kilo session.
- **Worktrees:** every chain of micro-briefs works in its own git worktree, which the first brief
  creates. The project card gives the exact pattern. Never work in a project's shared checkout.
- **Safety settings:** `~/.config/kilo/kilo.jsonc` lets Kilo run commands without asking, except
  `git push`, Convex commands and `rm`, which wait for the owner's click. He approves a push of the
  brief's own branch and rejects anything else. In Kilo's auto mode (the owner's choice) nothing
  asks, so the Commander checks after every run that `origin/main` has not moved.
- **Commands:** Kilo stops any command after 120 seconds, and starts every command in its own
  starting folder, keeping no `cd` or `export`. Every command in a brief carries its own `cd`.
- **Method B, after a smoke test on the owner's Kilo version:** one Kilo agent (mode) file per role in
  `.kilo/agents/<role>.md`, whose body only says "read `_team.md` and `<role>.md`". The brain stays
  in this repo, so there is one source.
  Smoke test: create `.kilo/agents/echo.md` whose body says "Reply only: ECHO OK"; open a session,
  pick that agent, send "hi"; it must reply exactly `ECHO OK`.

## 10. Token habits (W-006)
The spend laws are `LAW.md` 15 to 18 (W-007). `token-usage/TOKEN-HABITS.md` holds the habits around them,
measured from the owner's own spend (S-28). `token-usage/claude_token_usage.py` prints the exact Claude cost
of every session in dollars.

## 11. The roster

| Agent | Level | One skill | File |
|---|---|---|---|
| Brain Creator | Manage | Writes the law, the brains and the templates (tier `master`) | `agents/brain-creator.md` |
| Commander | Command | Plan, brief, audit, report (engineering) | `agents/commander.md` |
| Master-lite | Command | The Commander's job in short form, for any model | `agents/master-lite.md` |
| Marketing Manager | Command | Positioning, messaging, market intelligence | `agents/marketing-manager.md` |
| Lead | Senior | Verify findings, design the fix, find the lesson | `agents/lead.md` |
| Sniper | Audit | Diff against brief, line by line | `agents/sniper.md` |
| Shield | Check | Security Lead: threat model, orders the team, verdict (tier `sealed`: Opus, law 25) | `agents/shield.md` |
| Sec-authz, Sec-data | Check | Access audit; data and leak audit (tier `checker`) | `agents/sec-authz.md`, `agents/sec-data.md` |
| Sec-tools, Sec-redteam, Sec-fixer, Sec-keeper | Work | Scanners; exploit test; fix; regression test and rule | `agents/sec-*.md` |
| Engine-TS | Work | TypeScript server functions | `agents/engine-ts.md` |
| Engine-PY | Work | Python modules and their tests | `agents/engine-py.md` |
| Scribe | Work | Locale strings | `agents/scribe.md` |
| Painter | Work | Screen component look, from a full spec | `agents/painter.md` |
| Wirer | Work | Connect components to pages and the server | `agents/wirer.md` |
| Tester-Server | Work | Server tests | `agents/tester-server.md` |
| Tester-Screen | Work | Screen tests | `agents/tester-screen.md` |
| Sweeper | Work | Cleanup and version bumps | `agents/sweeper.md` |
| Mapper | Work | Build and refresh the code map | `agents/mapper.md` |
| Researcher | Work | Answer research questions from public web pages, every fact quoted and linked | `agents/researcher.md` |
| Fix Lead | Check | Audit findings to proven fixes through Kilo workers | `agents/fix-lead.md` |
| Demo-lead | Check | Demolition: brief from the target card (`templates/target-card.md`), re-run each break, route it | `agents/demo-lead.md` |
| Demo-fuzzer, Demo-chaos, Demo-racer, Demo-intruder, Demo-time, Demo-recorder | Work | Break the sandbox by inputs; step order; concurrency; attack list; time; then the smallest repro and failing test (shared rules: `agents/_demolition.md`) | `agents/demo-*.md` |
| Test Auditor | Check | Find every break no test catches; spot bent tests | `agents/test-auditor.md` |
| Research Checker | Check | Prove each research fact against its page | `agents/research-checker.md` |
| Content Checker | Check | Every published word true and allowed | `agents/content-checker.md` |
| Orchestrator | Manage | Runs the company across projects | `agents/orchestrator.md` |
| Eng Director | Manage | Engineering quality across projects | `agents/eng-director.md` |
| R&D Director | Manage | Research queue, proposals, model scouting | `agents/rnd-director.md` |
| Sales Director | Manage | Buyers, offers, pipeline; drafts only | `agents/sales-director.md` |
| Client Care | Manage | Live clients: incidents, follow-ups | `agents/client-care.md` |
| Copywriter | Work | Text drafts from a brief | `agents/copywriter.md` |
| Social Drafter | Work | Posts from a brief | `agents/social-drafter.md` |
| Log Reader | Work | Group errors from named logs | `agents/log-reader.md` |
