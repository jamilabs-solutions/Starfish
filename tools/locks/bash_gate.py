#!/usr/bin/env python3
"""bash_gate v1.2: PreToolUse hook, blocks every Bash command not on the read-and-hire list (P-004 M2)"""
import json
import os
import re
import shlex
import sys


def block(reason):
    print(f"bash_gate: blocked: {reason}", file=sys.stderr)
    sys.exit(2)


ALLOWED = {
    "ls", "cat", "head", "tail", "grep", "rg", "wc", "cut",
    "diff", "echo", "pwd", "sha256sum", "stat", "date", "which",
    "test", "true", "cd", "jl", "npm", "npx", "pytest",
}
GIT_SUBS = {"status", "log", "diff", "show", "branch", "rev-parse", "worktree",
            "merge", "commit", "add", "switch", "fetch", "push"}


def allowed(p, b, w):
    if any(word.startswith(("--output", "--pre", "--upload-pack", "--receive-pack", "--exec"))
           for word in w):
        return False
    if p in ALLOWED:
        if p == "npm":
            return len(w) > 1 and w[1] in ("test", "run")
        if p == "npx":
            return len(w) > 1 and w[1] in ("vitest", "playwright", "tsc")
        return True
    if b == "kilo" and len(w) > 1 and w[1] == "run":
        return True
    if p == "git" and len(w) > 1 and w[1] in GIT_SUBS:
        if any(word.startswith("--output") for word in w):
            return False
        return True
    if p == "python3":
        idx = 1
        if len(w) > 1 and w[1] == "-I":
            idx = 2
        if idx >= len(w):
            return False
        cand = w[idx]
        return cand.endswith(".py") and "tools/" in cand and not cand.startswith("-")
    if p in ("bash", "sh"):
        if len(w) < 2:
            return False
        cand = w[1]
        return (cand.endswith(".sh")
                and ("tools/check_" in cand or "agents/bench/run.sh" in cand)
                and not cand.startswith("-"))
    return False


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
        command = data["tool_input"]["command"]
    except Exception:
        block("invalid input")
        return
    if not isinstance(command, str):
        block("command is not a string")
        return

    cmd = command
    for t in ("2>/dev/null", ">/dev/null", "2>&1"):
        cmd = cmd.replace(t, "")

    if (">" in cmd or "<<" in cmd or "<(" in cmd or "`" in cmd or "$(" in cmd or "\n" in cmd):
        block("forbidden character in command")
        return

    if not cmd.strip():
        block("empty command")
        return

    for seg in re.split(r"&&|\|\||;|\||&", cmd):
        seg = seg.strip()
        if not seg:
            block("empty segment")
            return
        try:
            w = shlex.split(seg)
        except ValueError:
            block("unparseable segment")
            return
        if not w:
            block("empty segment")
            return
        p = w[0]
        b = os.path.basename(p)
        if not allowed(p, b, w):
            block(f"{b} not allowed")
            return

    sys.exit(0)


if __name__ == "__main__":
    main()