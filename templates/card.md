# Card template

> v1.0 · 2026-11-06 · written by the Brain Creator (W-010, `LAW.md` law 22, HANDBOOK section 8).
> A card is at most 120 words. Company cards go in `agents/memory/<role>.md`, project cards in
> `<project>/.jamilabs/cards.md`. Class test: "Would this card still be true in a new, empty repo with
> the same stack?" Yes: company (`jl:`). No: project (`<project>:`). Both: split it.
> A card never holds a live action (push, deploy, send, pay): those need their own go (H1).

Pointer line, in the file's Pointers table (one line per card):

| C-<scope>-<nnn> | <scope>:<role-stack>/<task-kind> | <try first, under 10 words> | <attempts> | <uses> | <failed uses> | PROPOSED |

Status: PROPOSED (Commander) -> PROBATION (a `checker`: scope, hard lines, source) -> PROVEN (3 clean
uses) · any failed use -> REVIEW · bad or stale -> RETIRED (kept, never deleted).

Card, under the file's Cards heading:

### C-<scope>-<nnn>
Fingerprint: <scope>:<role-stack>/<task-kind> · From: <project> <brief id> <YYYY-MM-DD> · Proof: <run-log row, commit>
Try first: <the route that passed: steps, or the script that replaced it>
Never: <route> · <why it failed> · <model> · <YYYY-MM-DD>
Never: <one line per failed route>
