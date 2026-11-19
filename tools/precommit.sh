#!/usr/bin/env bash
# precommit v1.0: the repo's pre-commit gate (K-001 keep, AG-001 leakcheck).
R="$(git rev-parse --show-toplevel)"
python3 -I "$R/tools/keep.py" precommit || exit 1
python3 -I "$R/tools/leakcheck.py" --staged >/dev/null || { python3 -I "$R/tools/leakcheck.py" --staged | grep '^NEW:' >&2; exit 1; }