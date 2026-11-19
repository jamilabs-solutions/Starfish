# W-005 · Agents are benchmarked; every rule change is measured

> Replaced by W-010 (2026-11-06): the bench is a replay tool, not a gate.

**Date:** 2026-10-24 · **Decided by:** the owner · **Status:** Accepted. Built and baselined 2026-10-24 (S-25).

## Context
the owner is holding business tasks until the team is structured, ready and tested. As knowledge, agents
and laws grow, the owner wants a quick comparison that shows whether a change improved the agents or degraded
them, tracked in a log inside the agents folder.

## Decision
- A bench in `agents/bench/`: fixed tasks per role, run in a synthetic throwaway repo, scored by
  scripts, one row per task in `agents/bench/LOG.md` (design in `agents/bench/README.md`).
- It runs unattended and free. Kilo's bundled CLI runs a task headless
  (`kilo run --dir <repo> --model <model>`), and its session database records tokens, cost, model id
  and time for every session (S-23). The bench pins one named free model: for the automatic router
  the database shows only `kilo-auto/free`, never the model behind it.
- No change to the law's first part, `_team.md`, a brain or a template ships with a WORSE verdict.
- Until the first baseline exists, brains and the law stay frozen, so the baseline measures exactly
  the team at work.

## Why
- Anthropic: build evaluations first, establish a baseline, then compare every change against it;
  iterate on observed behaviour, not assumptions (S-03).
- Rule files can lower agent success (S-13): a rule's value must be measured, not assumed.
- W-004 cuts rules to save tokens. Only a measurement shows a cut did not cost quality.
- Our own one-off test (S-22) already proved the method works on a free model.

## Consequences
- The bench is code (a fixture repo, a runner, scorers), so executors build it from Brain Creator
  briefs, and the Brain Creator audits it. Agents never score themselves.
- v1 has three tasks (Engine, Scribe, Sniper). Every other role gets a task later, one at a time.
- Running the bench starts Kilo sessions. the owner gave a standing go on 2026-10-24 for free, local
  bench runs and for the bench build briefs, run headless and back to back; any other Kilo session
  still needs a go.
- Once the bench is built, `HANDBOOK.md` section 8 gets the rule "measure before it ships".
