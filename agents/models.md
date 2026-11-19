# Models: which model runs each tier today

> v2.8 · 2026-11-19 · written by the Brain Creator (W-009, W-010; replaces `routing.md`). Brains name a tier,
> never a model. Model names live only in this file, and only the Brain Creator puts them here.

## Tiers (LAW.md law 18)
| Tier | Who | Models, best first | How it is started |
|---|---|---|---|
| `master` | Brain Creator, Orchestrator, directors, PM (Commander), final audits | Claude Opus, Claude Sonnet | the owner opens it, says the role (law 19) |
| `sealed` | The Security Brain Creator (`jl sec-brain`, the only writer of the security brains, law 25); Shield, the Security Lead; its team takes the tier its brain names | Writer: Claude Fable (the owner, 2026-11-12). Shield: Claude Opus, pinned by the owner | a master runs `claude -p "<hire prompt>" --model opus ...` the same way as a `checker` |
| `checker` | Auditors, Test Auditor, Fix Lead, Demolition Lead, card admission (law 22) | Claude Haiku (or better) | a master runs `claude -p "<hire prompt>" --model haiku --allowedTools "Bash Read Edit Write Grep Glob" < /dev/null` in the background (prompt first: the flag list eats what follows it) |
| `worker` | Every executor brain | the `worker` list below | `kilo run --model kilo/$(jl model worker <role>) ...` (`agents/bench/run.sh` has the recipe) |

Agent subagents: Haiku unless the owner names another (moved here from law 18, Law v1.11).
Security is never left to a `worker` model alone: a `checker` owns it and may hire workers for the legwork.
Any model may run a `master` brain in its short form (`master-lite.md`); its first audit is read by the owner.

## `worker` list (best first)
`jl model worker <role>` prints the first line Kilo still offers (`kilo models`) that is not retired from that role (law 24). Kilo changes its free models
often: a model that is gone is skipped, never waited for.

```
dots-studio/dots-3-note-preview:free
nvidia/nemotron-3-ultra-550b-a55b:free
nvidia/nemotron-3.5-super-vl:free
cohere/north-mini-code:free
```

Proof: screening, 1 run per task, `agents/bench/LOG.md` 2026-10-26. Since W-010 a model stays by its
record under the full audit, not by a bench score.

## Rules
- A model joins the `worker` list on trial: it runs real briefs under the full audit (W-010). Strikes
  remove it from a role: 3 in its last 10 runs there (`jl strikes <role> <model>`, law 24), or one
  bent test (G2, `memory/shame.md`), and the Brain Creator deletes its line for that role.
- The list is empty or every model is gone: put the free entries of `kilo models` on trial, then go on.
  Never stop a plan for this.
- Retired (law 24): `dots-studio/dots-3-note-preview:free` from Researcher: 5 strikes in 5 runs
  (P-002, 2026-11-09): a long write gets cut off, it loops, then runs an unlisted `rm`.
  Long-file writers (Scribe, Researcher) on it need the "write in parts" brief line first.
- Retired (law 24): `kilo-auto/free`, Kilo's router, from Sniper: 5 strikes in 5 runs (a project
  2026-10-24, `sniper.events.tsv`). It hides the model behind it, so no role uses it.
- Paid models (DeepSeek and others) need the owner's go before their first run.
- Any research output, from any model, is a claim: its checker opens every link and checks every quote.
