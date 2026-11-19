#!/usr/bin/env python3
"""git_guard v1.0.1: blocks discarding git commands in the shared tree (K-002)."""

import json
import os
import re
import sys

def main():
    data = json.load(sys.stdin)
    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = data["tool_input"].get("command", "")
    cwd = data.get("cwd") or os.getcwd()

    # Resolve ROOT
    guard_file = os.path.abspath(__file__)
    root_env = os.environ.get("JL_GIT_GUARD_ROOT")
    if root_env:
        ROOT = os.path.abspath(root_env)
    else:
        ROOT = os.path.dirname(os.path.dirname(guard_file))

    # DISCARD regex
    DISCARD = re.compile(
        r"\bgit\b[^;&|]*\b("
        r"reset\s+[^;&|]*--hard|"
        r"checkout\s+[^;&|]*--\s|"
        r"checkout\s+\.(\s|$)|"
        r"restore\s+(?![^;&|]*--staged)[^;&|]*|"
        r"clean\s+[^;&|]*-[a-zA-Z]*f|"
        r"stash(\s+(push|save)|\s*($|[;&|])))"
    )

    match = DISCARD.search(cmd)
    if not match:
        sys.exit(0)

    matched_text = match.group(0)

    # Check if target is shared tree
    resolved_cwd = os.path.abspath(cwd)
    root_abs = os.path.abspath(ROOT)

    # Condition (a): cwd is ROOT or inside ROOT, and path has no /jl-runs/
    cond_a = resolved_cwd.startswith(root_abs + os.sep) or resolved_cwd == root_abs
    cond_a = cond_a and "/jl-runs/" not in resolved_cwd
    if cond_a and os.path.isdir(resolved_cwd):
        import subprocess
        top = subprocess.run(["git", "-C", resolved_cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True).stdout.strip()
        cond_a = (top == "" or os.path.abspath(top) == root_abs)

    # Condition (b): cmd contains ROOT absolute path and does not contain jl-runs
    cond_b = root_abs in cmd and "jl-runs" not in cmd and ".worktrees" not in cmd

    if cond_a or cond_b:
        print(
            f'GIT GUARD: blocked "{matched_text}" in the shared tree: it discards uncommitted work of other sessions. Undo only your own change: git reset --soft HEAD~1, git restore --staged <your file>, rm <your file>. the owner runs it himself in a terminal if he wants it.',
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()