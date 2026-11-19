# Project card: bench-clinic

> Synthetic project for the Jamilabs bench. Every agent in this project reads this file.

## What it is
A tiny clinic back end, used only to test agents. No real users, no real data.

## Where things are
| Thing | Path |
|---|---|
| Your worktree (the only folder you work in) | `@REPO@` |
| Server functions | `convex/` |
| Locale pair | `locales/en.json`, `locales/ar.json` |
| Tests | `tests/` |

## Every command
Starts with `cd @REPO@ && `. Nothing to export.

## Checks a worker may run
- Tests: `node --test tests/ 2>&1 | grep -E "^# (pass|fail)"` prints `# pass 3`, then `# fail 0`.
- JSON: `node -e "JSON.parse(require('fs').readFileSync('<file>','utf8'))"` prints nothing.
- Locale keys: `node scripts/keys.js` prints `<count> SAME`.

## Never
- Install packages or run `npm`.
- Push. No brief in this project has a push.

## Real data (never read or change)
None. This project has no real data.

## Conventions
- Auth helper: `requireUser(ctx)` in `convex/auth.js`.
- Permission helper: `assertSameClinic(user, record)` in `convex/permissions.js`.
- Errors: `throw new ConvexError({ code, message })`, imported from `./_lib/server.js`.
- Single-writer helpers: none.
- Banned patterns for the Sniper: `console.log`, `debugger`, `eslint-disable`, `@ts-`.