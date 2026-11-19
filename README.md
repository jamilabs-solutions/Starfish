# Starfish

**An AI agent company made of plain files.**

A starfish has no central brain, and one arm can grow a whole new starfish. Starfish works the same
way: the company is a set of Markdown files (a law, one brain per role, memory, templates), not a
trained model. Clone it, and your copy grows into your own company.

## How it works
- **A law** (`LAW.md`): golden rules and hard lines every agent follows, whatever model runs it.
- **Brains** (`agents/`): 46 roles, one file each: commander, workers, auditors, a security team.
  A brain says what the role proves, what it never does, and the exact form of its report.
- **Tiers, not vendors:** a `master` model decides and audits, a `checker` audits, free `worker`
  models do the work. `./jl model worker <role>` picks today's free model.
- **Programs before models:** guards and checks are plain scripts in `tools/`: a leak check, a
  last-good file store, a git guard, a disk and RAM guard.
- **Memory that learns safely:** every run is logged; a lesson enters a brain only after it is
  proven (`wisdom/` holds why each rule exists).

## Start
1. Read `AGENTS.md`.
2. Run `./jl` to list the roles, `./jl <role>` to print a role's start-up text.
3. Point your AI tool at `LAW.md` (Claude Code through `CLAUDE.md`, Kilo through `AGENTS.md`).

## Licence
MIT. Made by Jamilabs.
