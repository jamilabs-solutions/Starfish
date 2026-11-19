#!/usr/bin/env python3
"""Acceptance check for cold_guard.py. Prints ALL 6 CASES PASSED or the first failing case."""
import json, os, subprocess, sys, tempfile
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
NOW = 1800000000.0
tmp = tempfile.mkdtemp()


def iso(t):
    return datetime.fromtimestamp(t, timezone.utc).isoformat().replace("+00:00", "Z")


def turn(ctx, ago_min, model="claude-opus-5-5", side=False):
    return json.dumps({"type": "assistant", "isSidechain": side, "timestamp": iso(NOW - ago_min * 60),
                       "message": {"model": model, "usage": {"input_tokens": 10, "cache_read_input_tokens": ctx - 10, "cache_creation_input_tokens": 0}}})


def run(name, lines, session):
    path = os.path.join(tmp, name + ".jsonl") if lines is not None else "/nonexistent"
    if lines is not None:
        open(path, "w").write("\n".join(lines) + "\n")
    hook = json.dumps({"session_id": session, "transcript_path": path, "prompt": "hello world"})
    env = dict(os.environ, COLD_GUARD_NOW=str(NOW), COLD_GUARD_DIR=tmp)
    p = subprocess.run([sys.executable, os.path.join(HERE, "cold_guard.py")], input=hook, capture_output=True, text=True, env=env)
    return p.returncode, p.stderr


def expect(case, got, code, *words):
    rc, err = got
    if rc != code or any(w not in err for w in words):
        sys.exit(f"FAIL case {case}: exit {rc}, stderr {err!r}")


expect(1, run("a", [turn(50000, 5)], "s1"), 0)
expect(2, run("b", [turn(250000, 5)], "s2"), 2, "250k tokens", "200k", "jl-handoff")
expect(2, run("b", [turn(250000, 5)], "s2"), 0)
expect(3, run("c", [turn(400000, 120)], "s3"), 2, "400k tokens", "idle 120 min", "$3.20", "Law 16: hand off with the jl-handoff skill", "cold_guard_prompt_s3.txt")
if open(os.path.join(tmp, "cold_guard_prompt_s3.txt")).read() != "hello world":
    sys.exit("FAIL case 3: the blocked message was not saved")
expect(3, run("c", [turn(400000, 120)], "s3"), 0)
expect(4, run("d", [turn(60000, 300)], "s4"), 0)
expect(5, run("e", None, "s5"), 0)
expect(6, run("f", [turn(300000, 120, model="claude-haiku-5-5"), turn(30000, 120, side=True), turn(40000, 5)], "s6"), 0)
print("ALL 6 CASES PASSED")
