# Thread card template (the Wise Man's decision threads)

> v1.0 · 2026-11-19 · written by the Brain Creator (P-006 W1). One file per decision:
> `agents/memory/wise-man/threads/T-NNN.md`. The card is the truth; `tools/mem_index.py` reads it and
> is never edited by hand. A card never holds a live action (H1).

```
# T-NNN: <decision title, under 10 words>
Project: <project folder, or jl for the company>
Plan: <plan id, or none>
Tags: <3 to 6 lower-case words, space separated>
State: OPEN | REVIEW | WATCH | CLOSED
Opened: <YYYY-MM-DD> · GO by: the owner
Predicted: <the effect we expect, one line>
Signal: <what to measure and where, one line>

## Log
- <YYYY-MM-DD> <state>: <what happened, one line, with a path to the proof>

## Answers
- Marketing: <effect seen vs Predicted, or "waiting: not live">
- Security: <hole yes/no; avoidable at planning yes/no; path to the answered question file>

## Verdict
<RIGHT | WRONG | PARTIAL, one line why. Empty until CLOSED.>

## Lessons
- [process|domain] [unchecked|checked] <at most 25 words> · tags: <words>
```

Rules: states move only as `plans/P-006-wise-man-memory.md` "A thread's life" says. A lesson is
written for each "avoidable at planning: yes" and each wrong prediction. `checked` means a second
thread confirmed it; the same lesson twice becomes a principle in `START.md`.

# START.md (the Wise Man's hot memory)

`agents/memory/wise-man/START.md`, cap 400 words (`wc -w`); a new line replaces an old one. Parts, in
order: `## Shared memory` (pointers only), `## Principles` (one line each, with the threads behind
it), `## Open threads` (one line each: id, title, state, the question to ask at start).
