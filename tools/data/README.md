# tools/data: the Data Analyst's programs

> v0.3 · 2026-11-18 · Brain Creator (P-007). One program per job; each with a fixture and a check.

## Engine
**DuckDB** (`SET memory_limit`, `temp_directory`), PROVEN by P-007 R1 (2026-11-17,
`../jl-runs/P-007/R1/results.tsv`): 1.12 GB CSV, 20M rows, 1 GB memory cap, 3 queries x 3 runs.
DuckDB 9/9 passed, 5.1 to 6.9 s, peak 630 to 750 MB. polars streaming 6/9 (q3 join killed, exit 143;
peak ~1.07 GB). pandas chunks 9/9, 15.7 to 27.1 s, peak 280 to 560 MB: the fallback when memory is
tighter than DuckDB's limit. Answers equal across engines (polars q1 sum off by 1: float order).

## Programs
- `chat_prep.py <run> <export.json>...`: Telegram export to `messages.tsv`, `scope.tsv`, `ledger.tsv`,
  `sha256.txt`, `windows.tsv`, `batches/` (default 100 messages, overlap 15, 5 windows a batch: (P)).
- `chat_check.py <run> <events.tsv>`: every window covered, every quote really in its messages, inside
  its window. `--diff a b`: what only one reader found.
- Check: `bash tools/data/check_chat_tools.sh` (17 PASS). Method: `agents/data/chat.md`.

A one-off needed twice is proposed here as a Kilo brief.
