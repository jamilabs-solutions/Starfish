#!/usr/bin/env python3
"""kilo_watch v1.0: live monitor of Kilo sessions (brief W1)."""

import argparse
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Live monitor of Kilo sessions")
    parser.add_argument("--db", default="~/.local/share/kilo/kilo.db", help="Path to Kilo database")
    parser.add_argument("--log", default="~/.local/share/kilo/log/opencode.log", help="Path to Kilo log file")
    parser.add_argument("--since-hours", type=float, default=12, help="Show sessions updated within this many hours")
    parser.add_argument("--title-prefix", default="", help="Filter sessions by title prefix")
    parser.add_argument("--quiet-min", type=int, default=3, help="Minutes idle before QUIET state")
    parser.add_argument("--stuck-min", type=int, default=10, help="Minutes idle before STUCK state")
    parser.add_argument("--once", action="store_true", help="Print one table and exit")
    parser.add_argument("--interval", type=int, default=30, help="Refresh interval in seconds")
    parser.add_argument("--notify", action="store_true", help="Desktop notifications for STUCK/FAILED")
    parser.add_argument("--now-ms", type=int, default=None, help="Current time in ms (for tests)")
    parser.add_argument("--no-proc", action="store_true", help="Treat all sessions as having no live process (for tests)")
    parser.add_argument("--id-of", default=None, help="Print the newest session id with this exact title, or none")
    parser.add_argument("--tools-of", default=None, help="Print each bash command of this session, one per line")
    parser.add_argument("--tokens-of", default=None, help="Print the total tokens of this session, or 0")
    return parser.parse_args()


def expand_path(path: str) -> str:
    return os.path.expanduser(path)


def connect_db(path: str) -> sqlite3.Connection:
    try:
        return sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    except sqlite3.OperationalError as e:
        print(f"kilo_watch: cannot open {path}", file=sys.stderr)
        sys.exit(1)


def get_sessions(conn: sqlite3.Connection, now_ms: int, since_hours: float, title_prefix: str) -> list:
    cutoff = now_ms - int(since_hours * 3600000)
    query = """
        SELECT id, title, model, time_created, time_updated, tokens_input, tokens_output
        FROM session
        WHERE time_updated >= ? AND title LIKE ?
        ORDER BY title
    """
    cursor = conn.execute(query, (cutoff, title_prefix + "%"))
    return cursor.fetchall()


def get_last_part_time(conn: sqlite3.Connection, session_id: str) -> Optional[int]:
    cursor = conn.execute(
        "SELECT MAX(time_updated) FROM part WHERE session_id = ?",
        (session_id,)
    )
    row = cursor.fetchone()
    return row[0] if row and row[0] is not None else None


def get_last_assistant(conn: sqlite3.Connection, session_id: str) -> Optional[dict]:
    cursor = conn.execute(
        """
        SELECT data FROM message
        WHERE session_id = ? AND json_extract(data, '$.role') = 'assistant'
        ORDER BY time_created DESC
        LIMIT 1
        """,
        (session_id,)
    )
    row = cursor.fetchone()
    if row:
        return json.loads(row[0])
    return None


def get_latest_part(conn: sqlite3.Connection, session_id: str) -> Optional[dict]:
    cursor = conn.execute(
        """
        SELECT data FROM part
        WHERE session_id = ?
        ORDER BY time_updated DESC
        LIMIT 1
        """,
        (session_id,)
    )
    row = cursor.fetchone()
    if row:
        return json.loads(row[0])
    return None


def get_error_parts(conn: sqlite3.Connection, session_id: str) -> list:
    cursor = conn.execute(
        """
        SELECT data FROM part
        WHERE session_id = ? AND json_extract(data, '$.type') = 'tool'
        AND json_extract(data, '$.state.status') = 'error'
        ORDER BY time_updated DESC
        LIMIT 5
        """,
        (session_id,)
    )
    return [json.loads(row[0]) for row in cursor.fetchall()]


def get_rate_limit_counts(log_path: str, now_ms: int) -> dict:
    rate_limit_counts = {}
    expanded_path = expand_path(log_path)
    if not os.path.exists(expanded_path):
        return rate_limit_counts
    try:
        file_size = os.path.getsize(expanded_path)
        read_size = min(2000000, file_size)
        with open(expanded_path, 'r', errors='ignore') as f:
            f.seek(max(0, file_size - read_size))
            lines = f.read().split('\n')
        cutoff_ms = now_ms - 10 * 60 * 1000
        keywords = ['Too Many Requests', 'Rate limit', 'rate limit', 'limited concurrency']
        for line in lines:
            if 'session.id=' not in line:
                continue
            if not any(kw in line for kw in keywords):
                continue
            match = re.search(r'session\.id=([^ ]+)', line)
            if not match:
                continue
            session_id = match.group(1)
            ts_match = re.search(r'timestamp=([^\s]+Z)', line)
            if not ts_match:
                continue
            try:
                ts_str = ts_match.group(1)
                ts_str = ts_str.replace('Z', '+00:00')
                ts = datetime.fromisoformat(ts_str).timestamp() * 1000
                if ts >= cutoff_ms:
                    rate_limit_counts[session_id] = rate_limit_counts.get(session_id, 0) + 1
            except (ValueError, AttributeError, TypeError):
                continue
    except (OSError, IOError):
        pass
    return rate_limit_counts


def is_session_alive(session_title: str, no_proc: bool) -> bool:
    if no_proc:
        return False
    try:
        for pid_dir in Path("/proc").iterdir():
            if not pid_dir.is_dir() or not pid_dir.name.isdigit():
                continue
            cmdline_path = pid_dir / "cmdline"
            try:
                cmdline = cmdline_path.read_text().split("\x00")
            except (OSError, PermissionError):
                continue
            has_kilo = any(arg.endswith("/kilo") for arg in cmdline)
            has_title = session_title in cmdline
            if has_kilo and has_title:
                return True
    except (OSError, PermissionError):
        pass
    return False


def compute_reason(last_assistant: Optional[dict], error_parts: list) -> str:
    texts = []
    if last_assistant and "error" in last_assistant:
        err = last_assistant["error"]
        texts.append(str(err.get("name", "")))
        texts.append(str(err.get("data", {}).get("message", "")))
    for part in error_parts:
        err = part.get("state", {}).get("error", "")
        texts.append(str(err))
    combined = " ".join(texts).lower()
    if not combined.strip():
        return "ended without finishing"
    if "rejected" in combined or "permission" in combined:
        return "permission rejected"
    if "invalid arguments" in combined:
        return "broken tool call"
    if "timeout" in combined or "etimeout" in combined or "600-second" in combined:
        return "provider timeout"
    if "429" in combined or "rate limit" in combined:
        return "rate limit"
    if "credits" in combined:
        return "needs paid credits"
    if "not found for account" in combined or "sign in" in combined:
        return "model unavailable"
    if "aborted" in combined:
        return "aborted"
    return combined[:40]


def compute_action(latest_part: Optional[dict]) -> str:
    if not latest_part:
        return ""
    ptype = latest_part.get("type", "")
    if ptype == "tool":
        tool = latest_part.get("tool", "")
        title = latest_part.get("state", {}).get("title", "")
        return f"{tool} {title}".strip()[:50]
    if ptype in ("reasoning", "text"):
        return "thinking"
    return ptype[:50]


def compute_state(alive: bool, idle_min: int, total_min: int, last_assistant: Optional[dict],
                  quiet_min: int, stuck_min: int, error_parts: list, rate_limit_count: int = 0) -> tuple[str, str]:
    if rate_limit_count > 0 and not (last_assistant and "error" not in last_assistant and last_assistant.get("finish") == "stop"):
        return "LIMITED", f"rate limited ({rate_limit_count} in 10 min)"
    if alive:
        if idle_min >= stuck_min:
            return "STUCK", ""
        if idle_min >= quiet_min:
            return "QUIET", ""
        return "WORKING", ""
    else:
        if idle_min < 2:
            return "WORKING", ""
        if last_assistant and "error" not in last_assistant and last_assistant.get("finish") == "stop":
            return "DONE", ""
        reason = compute_reason(last_assistant, error_parts)
        return "FAILED", reason


def format_tokens(tokens: int) -> str:
    if tokens >= 1000:
        return f"{tokens // 1000}k"
    return str(tokens)


def print_table(sessions_data: list, now_ms: int) -> None:
    local_time = time.strftime("%H:%M:%S", time.localtime(now_ms / 1000))
    if not args.once:
        print(f"kilo_watch · {local_time} · every {args.interval}s · Ctrl-C to stop")
    print("STATE    MIN  IDLE  TOKENS   MODEL                 TITLE                          LAST ACTION / REASON")
    for row in sessions_data:
        state, total_min, idle_min, tokens, model, title, action_reason = row
        print(f"{state:<8} {total_min:>4} {idle_min:>5} {tokens:>8} {model:<22} {title:<31} {action_reason}")
    states = [row[0] for row in sessions_data]
    counts = {s: states.count(s) for s in ["STUCK", "LIMITED", "FAILED", "QUIET", "WORKING", "DONE"]}
    summary = f"{len(sessions_data)} sessions · STUCK {counts.get('STUCK', 0)}"
    if counts.get('LIMITED', 0) > 0:
        summary += f" · LIMITED {counts.get('LIMITED', 0)}"
    summary += f" · FAILED {counts.get('FAILED', 0)} · QUIET {counts.get('QUIET', 0)} · WORKING {counts.get('WORKING', 0)} · DONE {counts.get('DONE', 0)}"
    print(summary)


def extract_model_id(model: str) -> str:
    if model.startswith("{"):
        try:
            data = json.loads(model)
            model_id = data.get("id") or f"{data.get('providerID', '')}/{data.get('modelID', '')}".strip("/")
            return model_id.replace("kilo/", "")[:21] if model_id else model.replace("kilo/", "")[:21]
        except (json.JSONDecodeError, TypeError, AttributeError):
            return model.replace("kilo/", "")[:21]
    return model.replace("kilo/", "")[:21]


def collect_session_data(conn: sqlite3.Connection, now_ms: int, since_hours: float, title_prefix: str,
                         quiet_min: int, stuck_min: int, no_proc: bool, rate_limit_counts: dict) -> list:
    sessions = get_sessions(conn, now_ms, since_hours, title_prefix)
    result = []
    for session in sessions:
        session_id, title, model, time_created, time_updated, tokens_in, tokens_out = session
        last_part_time = get_last_part_time(conn, session_id)
        last_ms = last_part_time if last_part_time is not None else time_updated
        idle_min = (now_ms - last_ms) // 60000
        total_min = (last_ms - time_created) // 60000
        alive = is_session_alive(title, no_proc)
        last_assistant = get_last_assistant(conn, session_id)
        latest_part = get_latest_part(conn, session_id)
        error_parts = get_error_parts(conn, session_id)
        action = compute_action(latest_part)
        rate_limit_count = rate_limit_counts.get(session_id, 0)
        state, reason = compute_state(alive, idle_min, total_min, last_assistant, quiet_min, stuck_min, error_parts, rate_limit_count)
        action_reason = reason if state in ("FAILED", "LIMITED") else action
        model_clean = extract_model_id(model)
        title_short = title[:30]
        tokens_total = tokens_in + tokens_out
        result.append((state, total_min, idle_min, format_tokens(tokens_total), model_clean, title_short, action_reason))
    state_order = {"STUCK": 0, "LIMITED": 1, "FAILED": 2, "QUIET": 3, "WORKING": 4, "DONE": 5}
    result.sort(key=lambda x: (state_order.get(x[0], 6), x[5]))
    return result


def notify_send(title: str, message: str) -> bool:
    try:
        subprocess.run(["notify-send", title, message], check=False, capture_output=True)
        return True
    except FileNotFoundError:
        print(f"NOTIFY: {title}: {message}")
        return False


def main() -> None:
    global args
    args = parse_args()
    db_path = expand_path(args.db)
    if not os.path.exists(db_path):
        print(f"kilo_watch: cannot open {db_path}", file=sys.stderr)
        sys.exit(1)
    now_ms = args.now_ms if args.now_ms is not None else int(time.time() * 1000)
    conn = connect_db(db_path)
    if args.id_of is not None:
        row = conn.execute("SELECT id FROM session WHERE title = ? ORDER BY time_created DESC LIMIT 1", (args.id_of,)).fetchone()
        print(row[0] if row else "none")
        sys.exit(0 if row else 1)
    if args.tokens_of is not None:
        row = conn.execute("SELECT tokens_input + tokens_output + tokens_reasoning + tokens_cache_read FROM session WHERE id = ?", (args.tokens_of,)).fetchone()
        print(row[0] if row and row[0] is not None else 0)
        sys.exit(0)
    if args.tools_of is not None:
        for (data,) in conn.execute("SELECT data FROM part WHERE session_id = ? AND json_extract(data, '$.type') = 'tool' AND json_extract(data, '$.tool') = 'bash' ORDER BY time_created", (args.tools_of,)):
            command = (json.loads(data).get("state", {}).get("input", {}) or {}).get("command", "")
            print(" ".join(str(command).split()))
        sys.exit(0)
    prev_states = {}
    first_loop = True
    try:
        while True:
            rate_limit_counts = get_rate_limit_counts(args.log, now_ms)
            sessions_data = collect_session_data(
                conn, now_ms, args.since_hours, args.title_prefix,
                args.quiet_min, args.stuck_min, args.no_proc, rate_limit_counts
            )
            if not args.once:
                print("\033[2J\033[H", end="")
            print_table(sessions_data, now_ms)
            if args.notify:
                current_states = {row[5]: row[0] for row in sessions_data}
                if not first_loop:
                    for title, state in current_states.items():
                        prev = prev_states.get(title)
                        if prev != state and state in ("STUCK", "LIMITED", "FAILED"):
                            row_data = next(r for r in sessions_data if r[5] == title)
                            reason = row_data[6]
                            notify_send(f"Kilo: {title}", f"{state}: {reason}")
                    working_quiet_stuck = sum(1 for s in current_states.values() if s in ("WORKING", "QUIET", "STUCK", "LIMITED"))
                    prev_working_quiet_stuck = sum(1 for s in prev_states.values() if s in ("WORKING", "QUIET", "STUCK", "LIMITED"))
                    if prev_working_quiet_stuck > 0 and working_quiet_stuck == 0:
                        notify_send("Kilo", "All runs ended")
                prev_states = current_states
                first_loop = False
            if args.once:
                break
            time.sleep(args.interval)
            now_ms = args.now_ms if args.now_ms is not None else int(time.time() * 1000)
    except KeyboardInterrupt:
        sys.exit(0)
    finally:
        conn.close()


if __name__ == "__main__":
    main()