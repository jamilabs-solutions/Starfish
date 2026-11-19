# W-004 · Laws support the agent, never slow it

**Date:** 2026-10-24 · **Decided by:** the owner · **Status:** Accepted. The way of thinking for every
agent that works, or will work, inside Jamilabs.

## Context
Reading `LAW.md` v0, the owner felt "we are building a maze": every session running through a set of md
files, a Singapore of laws that makes you hate living there. The bottleneck is the thin hair between
a law that boosts productivity and cuts tokens, and a law that delays the task and crashes the session.

Measured that day: a Kilo executor read about 1,840 words before its brief (`_team.md` 883, a brain
about 350, a project card 607). Law v0 would have added about 650 more (+35%), mostly
laws that only masters use.

## Decision
**Our laws exist to support the agent, never to slow it. We save tokens and time.**

1. **Choice test.** A line that removes a choice, or blocks a disaster, is a path. A line that adds a
   choice, a read or a step is a maze, and is cut.
2. **Compile, do not stack.** Like a GPS: the driver never reads the traffic code; the GPS gives the
   next turn and the traffic lights stop the car. The master reads the whole law and builds it into
   each brief, step by step. The executor reads only the "For every agent" part of `LAW.md`, its
   craft and its brief, with one fallback: anything the brief does not cover, stop and report.
3. **One hop.** One command prints everything an agent reads. No file sends it to another file.
4. **Caps.** Executor start-up at most 1,500 words before the brief; a brain at most 350 words; the law
   one page. At a cap, a new rule replaces an old one, and rules the models follow untold go first.

## Why
- Our own test (S-22): the plain prompt also scored 320/320. Rules bought speed and a full report;
  rules beyond that are pure cost.
- Weak models decay fastest as rules pile up (S-11, S-12). Every decision point costs: an agent that
  must decide whether to look something up often does not (S-14). A rule inside the brief needs no
  decision.
- Keep references one level deep (S-03). Aim for "the smallest possible set of high-signal tokens"
  (S-01). "If Claude already does something correctly without the instruction, delete it" (S-02).
- The training loop in `HANDBOOK.md` section 8 only ever adds: a broken rule "moves higher, gets
  louder, or gets a check step". Without caps, rules grow forever. That ratchet is the Singapore.

## Consequences
- `LAW.md` v0.2 is split: "For every agent" (about 250 words, hard lines and the executor fallback) and
  "For masters" (the rest, including laws 9 to 12 above).
- The executor hire command prints the law only up to the master part:
  `awk '/^## For masters/{exit} {print}' <JamiLabs root>/LAW.md`
- To meet the 1,500-word cap: `_team.md` goes from 883 to about 550 words (drop the lines the law now
  holds and its own maze lines, such as "Before you read a file, ask: is it worth reading"), and the
  project card from 607 to about 350.
- `HANDBOOK.md` section 8: AGENT SLIP may also replace a weaker rule; at a cap, cut first.
- Gate (planned): a word-count script fails when any capped file passes its cap.
