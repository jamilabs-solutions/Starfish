# Starfish

The Jamilabs agent company: law, brains, memory, templates and the `jl` tool. Model-neutral: any AI
tool that reads `AGENTS.md` starts here (W-010).

1. The law is `LAW.md`. Executors read only the part above "For masters"; masters read all of it.
2. Told your role ("you are the commander")? Run `./jl <role>` here, or `jl <role>` from any folder,
   and follow what it prints. `./jl` alone lists the roles.
3. Projects are separate repos; this repo never holds project code.

Adapters: Claude Code loads `LAW.md` through `~/.claude/CLAUDE.md`; Kilo through
`~/.config/kilo/AGENTS.md`; a chat app with no file access gets `jl paste <role>`.
