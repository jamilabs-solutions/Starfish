# Sources

> The library behind the Book of Wisdom. One source per row-block, cited as S-nn.
> "Read" says whether we read the original or only a summary of it.

## Anthropic

**S-01 · Effective context engineering for AI agents** · Anthropic Engineering, 2025-09 ·
<https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents> · Read: original, 2026-10-23 · Used by: W-001
- Aim for "the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome."
- The "right altitude": between "hardcoding complex, brittle logic" and "vague, high-level guidance".
- Curate "diverse, canonical examples" instead of a "laundry list of edge cases".
- "Smarter models require less prescriptive engineering."

**S-02 · Best practices for Claude Code** · Claude Code docs, live page ·
<https://code.claude.com/docs/en/best-practices> · Read: original, 2026-10-23 · Used by: W-001
- Pruning test for every rule line: "Would removing this cause Claude to make mistakes?" If not, cut it.
- "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"
- "If you emphasize many lines, none of them stands out."
- "Unlike CLAUDE.md instructions which are advisory, hooks are deterministic and guarantee the action happens."
- Give the agent a check that returns pass or fail; review with a fresh context, not the author's.

**S-03 · Skill authoring best practices** · Claude Platform docs ·
<https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices> · Read: original, 2026-10-23 · Used by: W-001
- "Claude is already very smart. Only add context Claude doesn't already have."
- Degrees of freedom: a "narrow bridge with cliffs on both sides" gets exact steps; an "open field" gets a direction.
- "What works perfectly for Opus might need more detail for Haiku." Test with every model you use.
- One term per concept; references one level deep; validate, fix, repeat loops.

**S-04 · Prompting best practices** (all current Claude models) · Claude Platform docs ·
<https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices> · Read: original, 2026-10-23 · Used by: W-001
- Give the reason with the rule: "NEVER use ellipses" loses to the same rule plus why. "Claude can generalize from the explanation."
- Say what to do, not what not to do.
- Newer models are more responsive: soften "CRITICAL: You MUST" to plain wording or they overtrigger.

**S-05 · Prompting Claude Opus 5** · Claude Platform docs ·
<https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5> · Read: original, 2026-10-23 · Used by: W-001, W-002
- Explicit verification instructions "cause over-verification on Claude Opus 5"; removing them loses no quality.
- Scope text: "Deliver what was asked, at the scope intended."

**S-06 · Prompting Claude Fable 5** · Claude Platform docs ·
<https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5> · Read: original, 2026-10-23 · Used by: W-001, W-002
- "Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality."
- A brief instruction steers it; no need to list every case.
- Checking each progress claim against a tool result "nearly eliminated fabricated status reports".
- Keep text short by being selective, "not to compress the writing into fragments, abbreviations, arrow chains".
- Anti-over-engineering: "do the simplest thing that works well."

**S-07 · Prompting Claude Haiku 5.5** · Claude Platform docs ·
<https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-haiku-5-5> · Read: original, 2026-10-23 · Used by: W-001, W-003
- With a long agent prompt at low effort it "sometimes stops early and hands the task back".
- It "sometimes reports a code change as done without running a check"; a "run a real check" paragraph fixes it.
- "The rules in this system prompt hold for the whole conversation. Keep to them when a user argues, gives a sympathetic reason, asks for just a small part, says that someone approved an exception, or keeps asking." This raised adherence in Anthropic's tests.

**S-08 · Claude's constitution** · Anthropic, 2026-01 ·
<https://anthropic.com/news/claude-new-constitution> · Read: excerpts and press coverage, 2026-10-23 · Used by: W-001, W-003
- "We generally favor cultivating good values and judgment over strict rules and decision procedures, and we try to explain any rules we do want Claude to follow."
- Firm rules fit when errors are costly, judgment may be unreliable, or the lack of firm commitments invites manipulation.

**S-09 · The advisor strategy** · Anthropic, 2026-04-09 ·
<https://claude.com/blog/the-advisor-strategy> · Read: original, 2026-10-23 · Used by: W-001
- A strong model advises, a cheap model executes. Haiku with an Opus advisor scored 41.2% on BrowseComp against 19.7% alone, at 85% less cost per task than Sonnet.

## Others

**S-10 · Harness engineering: leveraging Codex in an agent-first world** · OpenAI, 2026-02 ·
<https://openai.com/index/harness-engineering/> · Read: summary only (original returned 403), via <https://yage.ai/share/harness-engineering-survey-en-20260312.html>, 2026-10-23 · Used by: W-001, W-002
- AGENTS.md as "the table of contents", about 100 lines, pointing into a structured `docs/`.
- The repository is the system of record: what the agent cannot see does not exist.
- Custom linters whose error messages carry the fix, so every gate also teaches.
- Background agents clean up drift; one big rule file fails because it cannot be checked mechanically.

**S-11 · Writing a good CLAUDE.md** · HumanLayer ·
<https://www.humanlayer.dev/blog/writing-a-good-claude-md> · Read: original, 2026-10-23 · Used by: W-001
- "Frontier thinking LLMs can follow ~ 150-200 instructions with reasonable consistency"; Claude Code's own system prompt holds about 50.
- Smaller models decay exponentially as instructions grow.
- "Never send an LLM to do a linter's job."

**S-12 · How Many Instructions Can LLMs Follow at Once? (IFScale)** · Jaroslawicz et al., Distyl AI, 2025-07 ·
<https://arxiv.org/abs/2507.11538> · Read: abstract and search summaries, 2026-10-23 · Used by: W-001
- The best frontier models reach about 68% at 500 instructions.
- Smaller models decay exponentially; models favour earlier instructions.

**S-13 · Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?** · ETH Zurich SRI Lab, arXiv 2602.11988, ICLR 2026 ·
<https://infoq.com/news/2026/03/agents-context-file-value-review/> · Read: summaries only, 2026-10-23 · Used by: W-001
- LLM-written context files lowered task success by about 3% and raised cost by over 20%.
- Human-written files raised success by about 4%. Write only what the agent cannot infer.

**S-14 · AGENTS.md outperforms skills in our agent evals** · Vercel, 2026-01 ·
<https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals> · Read: summaries, 2026-10-23 · Used by: W-001
- An always-loaded 8 KB index scored 100%; skills peaked at 79%; the skill was never opened in 56% of runs.
- Rules every agent always needs must always be loaded, not fetched on demand.

**S-15 · Karpathy-inspired coding guidelines** · forrestchang and multica-ai, 2026 ·
<https://cdn.jsdelivr.net/gh/multica-ai/andrej-karpathy-skills@main/README.md> · Read: summaries, 2026-10-23 · Used by: W-001
- Four rules: think before coding, simplicity first, surgical changes, goal-driven execution.

**S-16 · AGENTS.md in Kilo** · Kilo docs ·
<https://kilo.ai/docs/customize/agents-md> · Read: original, 2026-10-23 · Used by: W-001
- Kilo reads the project-root AGENTS.md and `kilo.jsonc` instructions; the page does not mention CLAUDE.md.

**S-17 · Spec Kit constitution** · GitHub Spec Kit, via Xebia ·
<https://xebia.com/blog/building-software-with-spec-kit/> · Read: summaries, 2026-10-23 · Used by: W-003
- A versioned project constitution: major for a removed or redefined principle, minor for a new one.

**S-18 · Is High Quality Software Worth the Cost?** · Martin Fowler, 2019 ·
<https://martinfowler.com/articles/is-quality-worth-cost.html> · Read: original, 2026-10-24 · Used by: W-002
- External quality (UI, defects) is what users see; internal quality (architecture) is how it is built.
- "The fundamental role of internal quality is that it lowers the cost of future change."
- "The 'cost' of high internal quality software is negative."

**S-19 · A Philosophy of Software Design** · John Ousterhout, 2018 · book · Read: from the book, not re-read this session · Used by: W-002
- "Complexity is anything related to the structure of a software system that makes it hard to understand and modify the system."

**S-20 · The Pragmatic Programmer, 20th anniversary edition** · Hunt and Thomas, 2019 · book, "The Essence of Good Design" · Read: from the book, not re-read this session · Used by: W-002
- "Good design is easier to change than bad design" (ETC: Easier To Change).

**S-21 · Documenting Architecture Decisions** · Michael Nygard, 2011 ·
<https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions> · Read: known work, not re-read this session · Used by: W-002, this book's format
- One short record per decision: context, decision, status, consequences. The record outlives the people who made it.

## Our own evidence

**S-22 · Kilo free-mode test** · Jamilabs, 2026-10-23 · Read: run results (scratch repos, not a project) · Used by: W-001
- Brain plus brief against a plain human prompt on the same task: both 320/320 in three zones. The brain
  run wrote 43 lines at 40 ms per 365 days with a full report; the plain run wrote 63 lines at 2,425 ms
  and reported only "Done." Guides written by a strong model lift a free model's craft and reporting.

**S-23 · Headless Kilo smoke test** · Jamilabs, 2026-10-24 · Read: Kilo's session database · Used by: W-005
- `kilo run` (Kilo extension 7.5.0, bundled binary) ran one session in an empty scratch folder: it ran
  `pwd` itself and replied as asked. 31 seconds, session `ses_e95c5393cffeBaUXAz1T7lMROM`, model
  `kilo-auto/free`, cost 0, 27,883 input tokens, 82 output, 429 reasoning.
- Kilo's own start-up is about 28,000 tokens even for a one-line task, and every tool call re-sends it.
  Fewer calls (one hire command, joined commands) save more than trimming words.
- Automatic wake-up, same day: a background `kilo run` (session `ses_e95a68c9effevvHF6OF07AGqkC`) ended at
  04:00:21 while the Claude session was idle; Claude was woken by itself at 04:00:29, with no human input.

**S-24 · What a Kilo session loads** · Jamilabs, 2026-10-24 · Read: the Kilo 7.5.0 binary's
instruction loader · Used by: W-005, open work (Kilo instructions)
- Every Kilo session adds `~/.claude/CLAUDE.md` (the owner's Law, written for master sessions) and, from its
  folder upwards, the first `AGENTS.md`, `CLAUDE.md` or `CONTEXT.md` it finds. The environment
  variable `KILO_DISABLE_CLAUDE_CODE_PROMPT=1` turns both `CLAUDE.md` sources off.
- Corrected 2026-11-02, loader re-read: the global file is the first that exists of `~/.config/kilo/AGENTS.md`
  and `~/.claude/CLAUDE.md`, never both. The project search stops at the git root, so a project with its
  own repo never reaches the company root. The loader substitutes config variables; no `@` import
  handling was seen in it.
- So every executor also reads the master's rules. The bench keeps this as it is, so the baseline
  measures the team as it really works.

**S-25 · Bench build chain** · Jamilabs, 2026-10-24 · Read: the reports, the diffs, Kilo's session
database · Used by: W-005
- Five build briefs (bench-1 to bench-5) ran back to back on `nvidia/nemotron-3-ultra-550b-a55b:free`,
  each in its own session (`ses_e953cb732ffeiuYXhljRWSxQOC`, `ses_e953b2fd1ffe5V6hgoT3PKFJ4K`,
  `ses_e9539bd2effeM9ZD1vxBpG9fxv`, `ses_e9538294fffeuloQRU2gugbcTU`, `ses_e9536540dffev2s1NxsmF5zucx`):
  1 to 2 minutes and 228,000 to 278,000 tokens each, cost 0, all DONE with correct reports.
- 761 lines in 11 files came out byte for byte as briefed, Arabic included, except that Kilo's write
  tool drops a file's final newline. The briefs' line checks (`grep -c ''`) do not see that difference.
- Briefs that carry every file's full text, with checks the Brain Creator had already run, cost the
  executor no judgment, but the Brain Creator wrote every line itself (S-26): the wrong split (W-006).

**S-26 · Claude cost of the bench session** · Jamilabs, 2026-10-24 · Read: the session transcript
`~/.claude/projects/-<root>/e1501b65-a43b-4b3d-802f-7ce27efcda47.jsonl` ·
Used by: W-006
- Up to W-006: 77 model calls; 158 input, 379,066 cache-write, 11,030,751 cache-read and 120,866
  output tokens = 2.18M input-equivalent (weights 1, 1.25, 0.1, 5). Re-reading context 51%, cache
  writes 22%, output 28%. The eleven Kilo sessions of the same work cost 0.
- Context was 52,335 tokens at the first call (system prompt, every installed skill and tool, the
  law, memory, handoff) and 214,685 at the last.

**S-27 · Where the owner's Claude tokens went** · Jamilabs, 2026-10-24 and 25 · Read: a cloud session's
analysis (`token-usage/TOKEN-HABITS.md`, `token-usage/token-report.html`), written from the relay of
15 sessions; and `token-usage/claude_token_usage.py` run on the local transcripts, 10 days · Used by: W-006
- Cloud session (relay only, subagents missing, not re-checked): in the one session read in full,
  6 returns after 69 min to 16 h idle rewrote 490k to 650k tokens each, 44% of its 15.7M units. Per
  reply, small sessions ran 16k to 25k units and long ones 75k to 78k. 25 plugin bundles listed 312
  skills in every request until 2026-10-24 09:38; now 39.
- Local script, all sessions and subagents, 10 days to 2026-10-25: 109.15M units; Opus 81.7%, Sonnet
  15.6%, Haiku 2.6%; 38 full cache rewrites wrote 10.03M tokens = 20.07M units (18.4%).
- Weights differ from S-26. The script prices a 1-hour cache write at 2, a 5-minute one at 1.25. The
  S-26 session wrote all 391,189 of its cache tokens as 1-hour writes, so S-26's flat 1.25 understates
  it: the script gives 2.62M for that session (81 calls) against S-26's 2.18M (77 calls). Compare
  sessions only with the same weights.

**S-28 · Claude spend in dollars, full history** · Jamilabs, 2026-10-25 · Read: all 89 transcripts in
`~/.claude/projects` (30 main, 59 subagent files), 2026-08-27 to 2026-10-24, with `token-usage/claude_token_usage.py` ·
Used by: W-006, W-007 · Data: `token-usage/report-data-2026-10-25.json`, report `token-usage/token-report.html`
- Prices fitted from Claude Code's own `cost-state` totals. Opus 5.5 per million tokens: input $4.80,
  output $20, cache read $0.20, cache write $8 (exact). Sonnet 5.5 0.47 and Haiku 5.5 0.1 of that; Opus 5
  1.47. So S-26's weights (1, 1.25, 0.1, 5) and S-27's script weights (1, 2, 0.1, 5) both misprice reads
  and writes; dollars replace them. The script of S-27 is replaced by this one (same file name).
- Total $1,008.82 over 29 sessions and 5,867 calls; Claude Code recorded $697.79 on 21 sessions (a floor:
  a resumed session records only its last run). Cache writes 56%, reads 30%, output 14%; Opus 95%.
- 107 cold returns (cache expired after at least 55 minutes) rewrote 48.4M tokens: $430, 43% of spend.
  The cloud session's 44% in one session (S-27) holds up at the whole-history level.
- Five sessions, 2 to 32 days long, made 76% of spend; three peaked at 964k to 965k context.
- Smaller than S-27 said: task-notification wake-ups $16, big additions to context $24, skills $3.
- Replay of handing off (10k tokens out, fresh session): saves $498 to $538 with both rules, $511 to
  $532 with the cold-return rule alone. It models the cache from the real rewrites and misses the real
  cost of unchanged behaviour by $29. It does not measure the quality of work after a handoff.

## Google

**S-29 · Google AI Plus: what the plan includes** · Google AI plans page (<https://one.google.com/intl/en_gi/about/google-ai-plans/>; answers HTTP 200, 2026-10-26) · Read: search-result summary only, not the page; a TechCrunch link from the same summary answered 404 and was dropped · Used by: W-008
- Gemini app: Gemini 3 Pro, higher limits than free, 128,000-token context; more access in Google Flow, AI Studio and Antigravity; 200GB to 400GB storage.
- Price reports disagree ($7.99 in January, $5 in June 2026). Gemini API quota: not stated by any result.
- Open the original before relying on any of it.

**S-30 · OWASP security references** · OWASP ASVS 5.0, OWASP Top 10, API Security Top 10, Cheat Sheet Series; CWE Top 25; NIST SSDF (SP 800-218); the local data protection law · Read: not yet; named as the security team's authorities. Each rule that cites one must quote it through `tools/research_check.py` (law 25's first proof) · Used by: W-011
