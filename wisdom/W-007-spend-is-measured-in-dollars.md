# W-007 · Spend is measured in dollars, and four laws follow from the measurement

**Date:** 2026-10-25 · **Decided by:** the owner · **Status:** Accepted.

## Context
W-006 priced Claude cost in input-equivalent tokens (cache read 0.1, write 1.25). Claude Code's own
dollar records (S-28) fit Opus 5.5 exactly at input $4.80, output $20, cache read $0.20, cache write
$8 per million: read is 0.04 of input, write 1.6, output 4.

## Decision
- The cost metric is dollars per finished task, from `token-usage/claude_token_usage.py`.
- Four laws (LAW.md 15 to 18): Kilo first; do not go idle big; hand off at 200k; model by job.

## Why
- 107 cold returns cost $430 of $1,009 (43%). Five long sessions made 76%. Opus took 95%.
- A replay of the real sessions saved $498 to $538 with a handoff at 200k and no cold returns.
- Wake-ups, pasted material, screenshots and skills are each under 3%: no law.

## Consequences
- More, shorter sessions: each restart reads about 12k tokens ($0.46), so the Commander gets a resume
  pack of at most 1,500 words, built by a free model.
- Enforcement should not rely on memory: a status line showing context size and minutes idle (an
  executor brief) makes laws 16 and 17 visible at the moment of decision. Not built.
- Open: quality after a handoff is not measured; the Artifact tool and unused skills weigh about 15k
  tokens of every start-up (STARTUP-COST.md).
