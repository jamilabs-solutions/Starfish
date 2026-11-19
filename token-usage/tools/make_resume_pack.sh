#!/usr/bin/env bash
# Prints a resume pack for a new Commander session (law 16).
# Usage: make_resume_pack.sh <repo> "<next step>" [run log path]
repo="$1"; next="$2"; log="${3:-$repo/.jamilabs/runs/LOG.md}"
echo "# Resume pack: $(basename "$repo"), $(date -u '+%Y-%m-%d %H:%M') UTC"
echo
echo "> Built by make_resume_pack.sh. A new Commander session reads this file and the project card, then does NEXT."
echo
echo "## NEXT"
echo "$next"
echo
echo "## Git"
echo "branch: $(git -C "$repo" branch --show-current)"
echo "HEAD: $(git -C "$repo" rev-parse HEAD)"
echo "uncommitted files: $(git -C "$repo" status --short | wc -l)"
echo "worktrees:"
git -C "$repo" worktree list | sed 's/^/  /'
echo
echo "## Last commits"
git -C "$repo" log --oneline -8
echo
echo "## Last runs (newest last)"
if [ -f "$log" ]; then grep '^| 20' "$log" | tail -8; else echo "no run log at $log"; fi
