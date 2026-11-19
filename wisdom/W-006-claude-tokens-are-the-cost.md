# W-006 · Claude tokens are the cost; the codebook moves the work to free models

**Date:** 2026-10-24 · **Decided by:** the owner · **Status:** Accepted. Partly replaced by W-007 (the cost metric only).

## Context
The bench (W-005) measured Kilo's tokens, which are free. the owner: the cost to cut is Claude's. The
laws are a codebook (the owner's way of thinking; a memory of knowledge, decisions and the data behind
them; a hub for incoming information) that lets the weakest model finish a task as if the strongest
had done it, while Claude's tokens fall. Orchestrators too may be Kilo, Haiku or Sonnet.

## Decision
- The one cost metric is **Claude tokens per finished task**, input-equivalent (input 1, cache write
  1.25, cache read 0.1, output 5), read from the session transcript in `~/.claude/projects/` (S-26).
  Kilo tokens are free; the bench keeps them only as a time signal.
- Claude does only what a free model cannot: decide, write specs and acceptance checks, read score
  lines, change the law. Free models do the rest: read, write, retrieve, summarise, iterate until the
  checks pass, and audit first.
- Claude audits through machine checks that print a few lines, never by reading transcripts or whole
  diffs.
- Knowledge is stored to be read cheaply: a small index always loaded, entries fetched by id with one
  command, raw input filed by a free model with exact quotes that a script checks.
- Every strategy is measured on the bench, in Claude tokens and in quality, before it becomes a rule.

## Why
- The bench session (S-26) cost 2.18M input-equivalent Claude tokens over 77 calls. Re-reading the
  context on every call was 51%; Claude's own writing 28%, because it wrote every line of the bench
  into the briefs and Kilo only copied them. Start-up was 52,000 tokens before any work.
- Across all sessions the biggest single cost was returning to a big session after the cache expired:
  18% of 109M units in 10 days (S-27). Habits that follow from it: `token-usage/TOKEN-HABITS.md`.
- Free models execute exact briefs well (S-22, S-25), so the strong model's job is the spec, not the text.
- Context is finite and costly: keep the smallest set of high-signal tokens (S-01).

## Consequences
- The bench gets a Claude-cost meter and strategy experiments. First: full text in the brief against
  spec plus hidden checks with Kilo iterating.
- Claude sessions stay short and start fresh: every call re-reads the whole, growing context.
- Start-up packs: a free model prepares what a session must read; the session reads only the pack.
- Open: which store architecture reads cheapest; when a weak orchestrator escalates to Claude.
