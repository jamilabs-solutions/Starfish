# W-008 · The system is model-neutral: one routing table, a master brain any model can run

**Date:** 2026-10-26 · **Decided by:** the owner (plan agreed 2026-10-25) · **Status:** Accepted. Plan built; DeepSeek unproven; Gemini frozen (the owner, 2026-10-26: the free models can do the job).

## Context
Claude tokens run out (W-006, W-007). the owner has a DeepSeek API and Google AI Plus (Gemini app) and
wants the system to keep working on them. Brains are plain markdown (decision of 2026-10-23), so
the roles already belong to no vendor; what was missing was a master brain that is not Claude-only
and a record of who runs what.

## Decision
- `agents/routing.md`: one table, role to first model and fallback, with the proof each model has.
- `agents/master-lite.md`: the Commander's job in 350 words, for any model. Claude Opus keeps `commander.md`.
- `templates/gemini-research-prompt.md`: the Researcher's job, pasted by hand into the Gemini app;
  the result lands in the project's `.jamilabs/research/` and goes through the Research audit.
  Frozen: kept, not used, until free models fail a research task.
- Free models first: OpenRouter and Kilo's free models carry the work; a scout (a Researcher brief per
  source) finds candidates, and the bench decides which model gets which role.
- `BRAIN-CREATOR-HANDOFF.md` is written so a non-Claude session can start from it.
- A model gets a role only when its bench run matches BASELINE (W-005). No bench exists for masters.

## Why
- The cost lever is the same as W-006: the strongest model decides and checks, cheaper models work.
  A fallback keeps work going when the strongest is out of reach.
- Checking by a script or by the Commander's audit does not depend on who wrote the work, so the
  audit layers already make a weaker model safe to use.
- Source S-29 (summary only, unread original): Google AI Plus includes more Gemini app access; no
  source states Gemini API quota, so nothing here relies on it.

## Consequences
- Open: DeepSeek is not in Kilo's own provider config (the owner's setup, his key); the first paid bench
  run needs his go. `kilo models` lists DeepSeek and Gemini through Kilo's gateway, which is not his key.
- Open: a master bench (a fixed task a master model must brief and audit correctly) does not exist.
- Deviation: the first draft and this commit were made by a Sonnet 5.5 session, at the owner's word
  (Opus costs too much now). An Opus session audits when one is next opened.
