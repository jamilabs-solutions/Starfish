# W-010 · Brains that learn safely: memory instead of a bench

**Date** 2026-11-06 · **Decided by** the owner, with the Brain Creator · **Status** Accepted. `LAW.md` v1.6.
Replaces W-005 (the bench as a gate) and the Shield line of W-009.

## Context
The bench (W-005) measured a brain on one pinned model. Kilo drops models often (W-009), so a
BASELINE goes stale before it is used, and "better on model X" says little about the next model.
the owner: the target is not equal speed with Opus but equal quality after every audit phase: a cheap
model may need three sessions (do it, test it, prove no other answer fits) where Opus needs one.

## Decision
1. **The pipeline guarantees quality, not the model.** A result counts only after build, test and an
   independent proof by another session or model. A brain is judged by attempts to Complete and
   Claude tokens per task type, read from the logs over time.
2. **Closeout.** After Complete, every attempt is recorded as `route | min | tokens | ok`. The
   passed route and the failed ones become a card: "Try first" and "Never". Next time the master
   looks the task up (`jl recipe`) and the worker starts at the route that worked. The audit stays.
3. **Pointers, not reading.** Executors read a pointer line (~30 tokens) and, on a hit, one card of
   at most 120 words (~160 tokens). A lookup costs at most 300 tokens. The event log is never read
   by an executor.
4. **Two files per brain:** the brain (`agents/<role>.md`, changed weekly or on a FIX ASAP flag) and
   its memory (`agents/memory/<role>.md` cards, `<role>.events.tsv` events). Project cards live in
   the project (`.jamilabs/cards.md`). Test for the class: "Would this card still be true in a new,
   empty repo with the same stack?" Yes: company card. No: project card. Both: split it.
5. **Seven gates against contamination.** Scope (each brain lists what it may and may never learn),
   hard lines, source (only audited runs), proof (a replay shows fewer attempts or tokens, nothing
   worse), probation (3 clean uses), one writer (agents propose; the checker and the Brain Creator
   admit), rollback (git; a bad lesson takes everything its source added since with it). Cards pass
   gates 1, 2, 3 and 5; a change to a brain passes all seven.
6. **Retirement is training.** Deviations, rule breaks and invented output are strikes for an agent
   and model in a role. 3 in its last 10 runs retire the pair from the role; a bent test retires it
   at once (G2).
7. **Known road.** The strong car is never Claude: it is the best worker, with Claude auditing back
   and forth until the audit finds nothing. The same route passing 3 times moves the task to the
   cheapest worker, audit kept; 10 identical runs (values stripped) make it a script. In the audit
   loop, the same finding twice stops the loop: the brief is rewritten (BRIEF GAP).
8. **Specialists.** One brain, one specialty and stack. A task outside every scope gets a new
   specialist brain, never a stretched one. Engine became `engine-ts`.
9. **Security is sealed.** Only Opus writes the Shield brain and its memory. A rule enters only with
   the owner's direct go after three proofs: an authority's text (OWASP, CWE, NIST, vendor docs) with
   link and quote; a fresh Opus session with no context agreeing on its own; a sandbox test where the
   rule catches the hole and safe code passes. Shield runs on Opus, pinned by the owner.
10. **Model-neutral repo.** The agent company is its own repo, `Starfish` (projects are separate
    repos, ignored), readable by any AI tool through `AGENTS.md`.

## Why
the owner's two ways (2026-11-06): knowledge from study (the brains and research library, written by
Opus) plus experience (cards from real runs). Hands-on beats theory on a clash for that stack and
version; the clash is logged, never silently overwritten. A learning brain is a double-edged weapon:
a contaminated one learns wrong things and spreads them, hence the gates and rollback.

## Consequences
- The bench stays as a replay tool for gate 4; it is no longer a gate. `models.md` admits a model on
  trial under the full audit; strikes remove it.
- Costs: the Commander logs each attempt and proposes cards; a `checker` admits them; the Brain
  Creator reads each brain's memory weekly.
- Open: the research library (daily web updates, later); semantic search when cards pass ~200.
