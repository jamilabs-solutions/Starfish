# <ID>: <one-line title>

<!-- Commander: delete this block before handing the brief out.
- One brief: at most 5 questions, 5 competitors, 6 dimensions, a budget of 10 pages.
- A full research is a chain: R1 finds the competitors ("Who sells <what> in <market>, and at what
  price?"), then one brief per competitor or per topic, then a merge brief.
- Fill Product from the project memory and constitution. A fact you do not have: UNKNOWN; the
  Researcher stops and asks for it. At FOUNDATION, What, For whom and Market are enough.
- Default questions by stage; edit them to fit:
  FOUNDATION: Who has this problem, and how many are they? How do they solve it today? Who sells a
  solution, and at what price? What laws or rules apply? What do users complain about?
  BUILDING: no questions; the Comparison only.
  UPDATING: What did each competitor add in the last 12 months? What do their users complain about?
  PROMOTING: How does each competitor describe itself (headline, promise)? What does it charge?
  Where does it advertise?
- Merge brief: under Questions write "Merge: <path>, <path>"; it keeps the layout. Write its checks
  for IDs like R2-F1.
- A research brief has no Sniper. You audit its sources (commander.md, "Research audit").
-->

> Agent: researcher · Chain: <chain name>, part <k> of <n> · Base: <full commit hash> · Branch: research/<id>
> Worktree: <absolute path> · File: `.jamilabs/research/<id>.md` · Commit message: "<exact message>"

## Product
- What: <one line>
- For whom: <one line>
- Who pays: <one line, or UNKNOWN>
- Stage: <FOUNDATION | BUILDING | UPDATING | PROMOTING>
- Market: <country or region> · Search languages: <for example English, Arabic>
- Our facts (the Us column): <one line per dimension, or "none" at FOUNDATION>

## Questions
Q1 <question>
Q2 <question>

## Comparison
Competitors: <names and their sites, or "the ones Q1 finds, at most 5">
Dimensions: <at most 6, one per line>

## Web
Search the web and open at most <10> public pages, only for these questions.

## Step 0: preflight
<First brief of a chain:>
`cd <repo> && git worktree add -b research/<id> <worktree> <base>`
<Every brief:>
`cd <worktree> && pwd && git branch --show-current && git rev-parse HEAD && git status --short && mkdir -p .jamilabs/research && date +%F`
EXPECTED:
```
<worktree>
research/<id>
<base, or the previous audited commit>
<today's date: write it in the file>
```

## Layout
Copy exactly; fill every `<...>`. At FOUNDATION, drop the Us column.
```
# Research <brief id>: <title>
Stage: <stage> · Market: <market> · Date: <Step 0 date> · Pages opened: <n>

## Answers
### Q1 <question, copied from the brief>
- <one fact> [F1]
- NOT FOUND: searched "<query>", "<query>"

## Comparison
| Dimension | Us | <competitor> | <competitor> |
|---|---|---|---|
| <dimension> | <our fact from the brief> | <fact> [F2] | NOT FOUND |

## Gaps seen
- <a need or complaint a page states that no listed competitor meets> [F3]

## Sources
| ID | URL | Quote | Page date |
|---|---|---|---|
| F1 | <url> | "<exact words>" | <date shown on the page, or none> |
```

## Writing the file (in parts: one big write fails and loops)
1. First write: only the header lines, `## Answers`, the other section headings and the Sources table header.
2. Then one edit per question: its facts under `## Answers`, its source rows under the table. At most 40 lines per write.
3. A write fails: retry once with half the text. Never delete, move or rewrite the whole file.
4. Your final message is the report only: never repeat the findings in it.

## Checks and commit
1. `cd <worktree> && F=.jamilabs/research/<id>.md && grep -c '^### Q' $F && grep -c '^| F[0-9]' $F && grep -oE '\[F[0-9]+\]' $F | sort -u | wc -l`
   EXPECTED: <the number of questions>, then two equal numbers.
2. `cd <worktree> && grep -oE 'https?://[^ |"<>)]+' .jamilabs/research/<id>.md | sort -u | while read -r u; do curl -s -o /dev/null -L --max-time 6 -w "%{http_code} $u\n" "$u"; done`
   EXPECTED: one line per link, each starting with 200. Any other line: list it under DEVIATIONS and send your final report; do not stop without one.
3. `cd <worktree> && git add .jamilabs/research/<id>.md && git commit -m "<exact message>" && git status --short`
   EXPECTED: the commit line, then nothing.

## Report
Use `_team.md` section 5. Under CHECKS, paste Step 0 and checks 1 to 3, raw.
