#!/usr/bin/env python3
"""UserPromptSubmit hook: block the first message sent to a cold or oversized session (laws 16 and 17).

Reads the hook JSON on stdin. Exit 0 lets the message through. Exit 2 blocks it and shows stderr to the
user; sending the same message again passes, because a stamp file silences the guard for QUIET_MIN.
"""
import json, os, sys, time
from datetime import datetime

COLD_MIN, COLD_CTX, BIG_CTX, QUIET_MIN = 50, 100000, 200000, 60
WRITE_PER_M = 8.0  # dollars per million tokens, Opus 5.5 cache write


def last_turn(path):
    """Context tokens and epoch seconds of the newest main-thread reply, or None."""
    best = None
    try:
        lines = open(path, errors="replace").read().splitlines()
    except OSError:
        return None
    for line in lines:
        try:
            e = json.loads(line)
        except ValueError:
            continue
        m = e.get("message") or {}
        if e.get("type") != "assistant" or e.get("isSidechain") or not m.get("usage") or "haiku" in m.get("model", ""):
            continue
        u = m["usage"]
        ctx = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
        best = (ctx, datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00")).timestamp())
    return best


def main():
    hook = json.load(sys.stdin)
    turn = last_turn(hook.get("transcript_path", ""))
    if not turn:
        return 0
    ctx, then = turn
    now = float(os.environ.get("COLD_GUARD_NOW") or time.time())
    idle = int((now - then) / 60)
    cold = idle >= COLD_MIN and ctx >= COLD_CTX
    if not (cold or ctx >= BIG_CTX):
        return 0
    stamp = os.path.join(os.environ.get("COLD_GUARD_DIR", "/tmp"), "cold_guard_" + str(hook.get("session_id", "x")))
    try:
        if now - float(open(stamp).read()) < QUIET_MIN * 60:
            return 0
    except (OSError, ValueError):
        pass
    open(stamp, "w").write(str(now))
    saved = stamp.replace("cold_guard_", "cold_guard_prompt_") + ".txt"
    open(saved, "w").write(str(hook.get("prompt", "")))
    if cold:
        print(f"Cache guard: this session holds {ctx // 1000}k tokens and was idle {idle} min, so its cache has expired. "
              f"Law 16: hand off with the jl-handoff skill (jl handoff) and end. Sending here writes about ${ctx * WRITE_PER_M / 1e6:.2f} of cache now, and every "
              f"later turn re-reads all of it; a new session from the handoff starts small. "
              f"Send again to continue here anyway. Your message is saved in {saved}.", file=sys.stderr)
    else:
        print(f"Cache guard: this session holds {ctx // 1000}k tokens (law: hand off at 200k). "
              f"Run the jl-handoff skill (jl handoff), then start a new session, or send again to continue here. Your message is saved in {saved}.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
