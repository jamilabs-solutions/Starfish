# W-001 · One law for every agent, in three layers

**Date:** 2026-10-24 · **Decided by:** the owner, on the master's research · **Status:** Accepted.
`LAW.md` v1.0 live since 2026-10-24.

## Context
the owner wants every Jamilabs product built inside one frame, by any model from a free Kilo executor
to Opus, in the fewest tokens. The laws must lift weak models to a strong engineer's way of working
without holding strong models back: "take the baby's hand", never cage the expert.

## Decision
Three layers, each with one job:

| Layer | Holds | Loaded by |
|---|---|---|
| 1. Gates | The hard lines, enforced by machines: CI, git hooks, permission rules, branch protection | Nobody; they block the action |
| 2. The Law (`LAW.md`) | Hard lines and outcomes, each with its reason. One page | Masters: all of it. Executors: only "For every agent" (W-004) |
| 3. Craft | How to meet the law, step by step: `agents/_team.md`, agent brains, the brief template, checklists | Executors always; strong sessions only on demand |

Project facts stay in each project's card and constitution.

## Why
- **The same sentence helps a weak model and hurts a strong one.** Anthropic tells you to add "run a
  real check" for Haiku 5.5 (S-07) and to remove verification instructions for Opus 5 (S-05); skills
  written for older models degrade Fable 5 (S-06). So everyone gets outcomes; only weak models get
  procedures.
- **Weak models break first as rules pile up** (S-11, S-12). Bloated rule files get ignored (S-02).
  LLM-written rule files lowered success (S-13). So the law stays short and human-reviewed.
- **Rules every agent always needs must always be loaded** (S-14).
- **A rule with its reason carries over to new cases** (S-04, S-08). Firm rules are kept for costly
  mistakes, unreliable judgment, and pressure (S-08).
- **Only machines give zero tolerance.** Prose is advisory and hooks are deterministic (S-02). A
  linter that prints the fix also teaches (S-10).
- **A strong planner with a cheap executor works** (S-09, S-22): that is the Jamilabs master and
  executor split.

## How a law is written
1. One law, one line or two: the rule, then its reason.
2. State the outcome, not the procedure. The procedure goes in craft.
3. At most five hard lines. They come first, because models favour early instructions (S-12).
   Only they say "Never".
4. Plain words, full sentences, one term per idea. Cut rules, never words: no shorthand or arrows (S-06).
5. Add a law only after a real failure that no gate can catch. Delete a law the models already obey
   without it (S-02 pruning test).
6. Every hard line gets a gate (table below).

## Consequences
- **Delivery.** Claude Code: `~/.claude/CLAUDE.md` imports `LAW.md`, so every session on this machine
  loads it. Not the root `CLAUDE.md`: sessions opened through the shortcut paths outside the
  JamiLabs folder (the projects) never load that file. Kilo never reads `CLAUDE.md` (S-16), so the hire command in `HANDBOOK.md` prints the law's
  "For every agent" part first (W-004).
- **No rule in two places.** After approval, `_team.md` (Brakes, Truth) and the owner's Law
  (`~/.claude/CLAUDE.md`, guard rails) drop the lines the law now holds and keep only their craft.
- **Cost.** Masters read about 660 words; executors about 250 (amended by W-004, 2026-10-24).
- **Gate map v0:**

| Law | Gate | Status |
|---|---|---|
| H1 live actions | Kilo asks before `git push`, Convex and `rm`; Commander checks `origin/main` after each auto-mode run | Exists |
| H1 live actions | Branch protection on each deployed `main`; Claude Code deny rules for deploy commands | Planned |
| H2 secrets, data, messages | Secret scan in pre-commit and CI; deny rules on reading `.env*` | Planned |
| H3 evidence | CI on every branch; Sniper audit; Commander real audit | Audits exist; CI per project |
| H4 weakened checks | CI fails when the test count drops or a skip marker appears | Planned |
| H5 one writer | Only the Brain Creator commits `LAW.md` and `agents/` | Process only |
| 9 traceability | Commit-message hook: every commit names its brief or plan step | Planned |

- **Q1, resolved 2026-10-24: the owner said yes.** Hard lines hold in every project; on everything
  else the project constitution wins (law 8, `HANDBOOK.md` section 2). The question was: `HANDBOOK.md` section 2 said "A project's own constitution wins for that
  project." Law 8 (v0.2) says a project may only add rules or be stricter. Recommendation: hard lines are
  company-wide and no project can loosen them; on everything else the project constitution wins.
