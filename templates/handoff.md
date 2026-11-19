# Handoff: one file per project (LAW.md laws 16, 17)

**One file only.** The JamiLabs root holds the master seats (brain, lead, wise-man, shield...); each project root holds its commander seat. No other handoff file exists: not per session, not per topic. Reports and incidents are not handoffs; they live in plans/ or memory/.

One `HANDOFF.md` at the project root. A Highlights block (≤15 lines, shared) and one section per
seat (brain, lead, wise-man…). Old sections go to `handoffs/archive/`, read-only; never edit them.
The script does every file action; the model only writes the draft.

**Start a session:** `jl handoff read <seat>`. Open an archive file only when a pointer sends you.
`PATHS: MISSING` or `ARCHIVE TAMPERED`: stop and tell the owner.

**Hand off** (the owner says so, law 16 idle 55 min, law 17 at 200k or brief done):
1. `jl handoff read <seat>`: see what the next session will see.
2. Write a draft (`/tmp/handoff-<seat>.md`), ≤400 words, only these headings:
   **Threads** (one line per open thread: id · state · next action · pointer to its plan or log) · **Now** (what is in progress, where) · **Next** (the exact next action) · **Waiting on** (whom,
   for what) · **New facts** (one line each, with a `path` or `path:line` pointer) · **Open
   questions**.
3. Never copy rules, laws, memory or old handoffs: point to them. Numbers: point to the file and line
   that holds them; copy only if no file holds them, exactly.
4. Before the draft: a correction from the owner → memory; a decision → `memory/decisions.md`; a lesson
   → the brain's events file. The draft points to them.
5. Check: every pointer exists, every number matches its source, every open item from the last
   section is closed, carried, or dropped with a reason.
6. `jl handoff write <seat> /tmp/handoff-<seat>.md --owner <session name>`. `--take` only when the
   owner session has ended. A Highlights change: `jl handoff highlights <file>` (≤15 lines; a new
   line replaces an old one).
7. Report: `Handoff done, <n> words. New session: jl <role>, then jl handoff read <seat>.`

**Refusals** (fix and re-run, never work around): over 400 words, missing path, secret pattern,
seat owned by another live session, highlights over 15 lines, archive changed.
