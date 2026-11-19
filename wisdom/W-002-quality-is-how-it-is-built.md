# W-002 · Quality is how a product is built

**Date:** 2026-10-24 · **Decided by:** the owner · **Status:** Accepted

## Context
Asked what "premium quality" means for a Jamilabs app, the owner answered: not how it looks and not where
it runs (mobile app, web app, Chrome extension). Quality is judged by how it was built.

## Decision
A Jamilabs product is high quality when it is:

1. **Cheap to change.** A modification touches few places and costs little.
2. **Flexible.** It adapts to new needs because its parts are small, separate and clearly named,
   not because it guessed the future.
3. **Rebuildable.** Its docs explain what it is, why each big choice was made, and how to run it,
   well enough to rebuild the product from them.
4. **Traceable.** Beyond version control, a dated log of every run, every plan change and every
   deviation shows exactly when and why we left the plan, so we can step back to that point.

## Why
- This is what the field calls internal quality: "The fundamental role of internal quality is that it
  lowers the cost of future change", and its cost is "negative" (S-18). Complexity is whatever makes
  a system "hard to understand and modify" (S-19). "Good design is easier to change than bad design" (S-20).
- Decisions outlive the people who made them only if they are written down with their context (S-21).
  For agents, what is not in the repository does not exist (S-10).
- Flexibility and "no over-engineering" (S-05, S-06) look opposed. They meet in one rule: flexibility
  comes from simplicity and separation, never from speculative layers.

## Consequences
- `LAW.md` laws 4, 5, 8 and 9 carry this definition to every agent.
- `PLAYBOOK.md` Part 5, "The quality bar", starts from this entry when it is written with the owner.
- **Gap found today.** Worker reports are chat messages and are not stored. Run traces existed only for
  briefs with a finding, so there was no complete log of runs.
- **Closed 2026-10-24:** `templates/run-log.md` gives each project one file, `.jamilabs/runs/LOG.md`,
  with one row per brief and a "Plan changes" table, so the whole trail is in one place.
  `HANDBOOK.md` section 8 and `commander.md` v1.2 require it.
- **Still planned:** commit messages that name their brief, enforced by a hook (W-001 gate map).
