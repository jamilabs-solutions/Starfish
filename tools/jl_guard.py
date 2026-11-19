#!/usr/bin/env python3
"""jl_guard v1.0: warns when disk or RAM is nearly full (G-001)."""

import os
import sys
import json
import time
import subprocess
from pathlib import Path

# Constants (tunable by the owner)
DISK_WARN_FREE, DISK_CRIT_FREE = 0.10, 0.05
DROP_WARN, DROP_CRIT = 3e9, 10e9
BIG_WARN, BIG_CRIT = 2e9, 8e9
RAM_WARN, RAM_CRIT = 1.0e9, 0.5e9
SWAP_WARN = 0.60
REPEAT_MIN = 60

def disk():
    """Return (free, total) bytes of / or from JL_GUARD_DF_FILE if set."""
    if "JL_GUARD_DF_FILE" in os.environ:
        with open(os.environ["JL_GUARD_DF_FILE"]) as f:
            total, free = map(int, f.read().split())
            return free, total
    s = os.statvfs("/")
    return s.f_bavail * s.f_frsize, s.f_blocks * s.f_frsize

def ram():
    """Return (mem_total, mem_avail, swap_total, swap_free) in bytes."""
    path = os.environ.get("JL_GUARD_MEMINFO", "/proc/meminfo")
    info = {}
    with open(path) as f:
        for line in f:
            k, v = line.split(":", 1)
            info[k.strip()] = int(v.split()[0]) * 1024
    return (info["MemTotal"], info["MemAvailable"],
            info["SwapTotal"], info["SwapFree"])

def bigfiles():
    """Return 5 largest files as (bytes, path) under JL_GUARD_BIG_ROOTS or defaults."""
    roots = (os.environ.get("JL_GUARD_BIG_ROOTS", "/var/log:/tmp")
             .split(":"))
    roots = [os.path.expanduser(r) for r in roots]
    dev_root = os.stat("/").st_dev
    files = []
    for root in roots:
        try:
            for dirpath, dirnames, filenames in os.walk(root):
                try:
                    if os.stat(dirpath).st_dev != dev_root:
                        dirnames[:] = []
                        continue
                except (OSError, FileNotFoundError):
                    dirnames[:] = []
                    continue
                for name in filenames:
                    path = os.path.join(dirpath, name)
                    try:
                        size = os.path.getsize(path)
                        if size >= BIG_WARN:
                            files.append((size, path))
                    except (OSError, FileNotFoundError):
                        pass
        except (OSError, FileNotFoundError):
            pass
    files.sort(reverse=True)
    return files[:5]

def drop():
    """Return drop (bytes) in last ~60 minutes or 0 if no sample in that window."""
    state_dir = os.path.expanduser(os.environ.get("JL_GUARD_STATE_DIR",
                                                    "~/.local/state/jl-guard"))
    Path(state_dir).mkdir(parents=True, exist_ok=True)
    state_file = os.path.join(state_dir, "state.json")
    now = float(os.environ.get("JL_GUARD_NOW", time.time()))
    free, _ = disk()

    state = {"free": [], "last": {"level": "OK", "epoch": 0}}
    if os.path.exists(state_file):
        try:
            state = json.load(open(state_file))
        except (json.JSONDecodeError, OSError):
            pass

    state["free"].append([now, free])
    state["free"] = [[e, f] for e, f in state["free"]
                     if now - e <= 3 * 3600]

    target_age = 3600
    best = None
    for epoch, old_free in state["free"]:
        age = now - epoch
        if 2400 <= age <= 5400:
            if best is None or abs(age - target_age) < abs(best[0] - target_age):
                best = (age, old_free)

    with open(state_file, "w") as f:
        json.dump(state, f)

    return max(0, best[1] - free) if best else 0

def top_users():
    """Return (disk_lines, ram_lines) or ([], []) if JL_GUARD_NO_TOP=1."""
    if os.environ.get("JL_GUARD_NO_TOP") == "1":
        return [], []
    disk_lines, ram_lines = [], []
    try:
        result = subprocess.run(
            ["du", "-xk", "--max-depth=1", "/var", f"/home/{os.environ.get('USER', 'root')}"],
            capture_output=True, text=True, timeout=60)
        sizes = []
        for line in result.stdout.strip().split("\n"):
            if line.strip():
                size_kb, path = line.split(None, 1)
                sizes.append((int(size_kb), path))
        sizes.sort(reverse=True)
        for size_kb, path in sizes[:5]:
            disk_lines.append(f"{path} {size_kb / 1024 / 1024:.1f} GB")
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError):
        pass
    try:
        result = subprocess.run(["ps", "-eo", "rss=,comm="],
                              capture_output=True, text=True, timeout=60)
        cmd_rss = {}
        for line in result.stdout.strip().split("\n"):
            if line.strip():
                parts = line.split(None, 1)
                if len(parts) == 2:
                    rss, comm = parts
                    cmd_rss[comm] = cmd_rss.get(comm, 0) + int(rss)
        ram_lines = [f"{c} {r // 1024} MB" for c, r in
                    sorted(cmd_rss.items(), key=lambda x: -x[1])[:4]]
    except (OSError, subprocess.TimeoutExpired, ValueError):
        pass
    return disk_lines, ram_lines

def level_disk(free, total):
    """Return OK, WARN or CRIT based on free space fraction."""
    frac = free / total if total else 0
    return "CRIT" if frac < DISK_CRIT_FREE else ("WARN" if frac < DISK_WARN_FREE else "OK")

def level_drop(drop_bytes):
    """Return OK, WARN or CRIT based on drop."""
    return "CRIT" if drop_bytes >= DROP_CRIT else ("WARN" if drop_bytes >= DROP_WARN else "OK")

def level_bigfile(big_files):
    """Return OK, WARN or CRIT based on largest file."""
    if not big_files:
        return "OK"
    largest = big_files[0][0]
    return "CRIT" if largest >= BIG_CRIT else ("WARN" if largest >= BIG_WARN else "OK")

def level_ram(avail):
    """Return OK, WARN or CRIT based on available RAM."""
    return "CRIT" if avail < RAM_CRIT else ("WARN" if avail < RAM_WARN else "OK")

def level_swap(swap_total, swap_free):
    """Return OK or WARN based on swap used fraction."""
    if swap_total == 0:
        return "OK"
    used_frac = 1 - (swap_free / swap_total)
    return "WARN" if used_frac >= SWAP_WARN else "OK"

def worst_level(*levels):
    """Return worst level: CRIT > WARN > OK."""
    if "CRIT" in levels:
        return "CRIT"
    return "WARN" if "WARN" in levels else "OK"

def format_gb(b):
    """Format bytes as GB with one decimal."""
    return f"{b / 1e9:.1f} GB"

def format_pct(frac):
    """Format fraction as percentage with no decimals."""
    return f"{frac * 100:.0f}%"

def main() -> int:
    """Main entry point. Return 0 for OK, 1 for WARN, 2 for CRIT."""
    once = "--once" in sys.argv
    notify = "--notify" in sys.argv
    full = "--full" in sys.argv

    free, total = disk()
    mem_total, mem_avail, swap_total, swap_free = ram()
    drop_bytes = drop()
    big_files = bigfiles()

    level_d = level_disk(free, total)
    level_dr = level_drop(drop_bytes)
    level_b = level_bigfile(big_files)
    level_r = level_ram(mem_avail)
    level_s = level_swap(swap_total, swap_free)

    overall_level = worst_level(level_d, level_dr, level_b, level_r, level_s)

    report = f"GUARD {overall_level}\n"
    report += f"DISK /: {format_pct(1 - free / total)} used, {format_gb(free)} free of {format_gb(total)}\n"

    if level_dr in ("WARN", "CRIT"):
        report += f"  drop: {format_gb(drop_bytes)}\n"

    if level_b in ("WARN", "CRIT"):
        for size, path in big_files[:3]:
            report += f"  big file: {path} {format_gb(size)}\n"

    disk_lines, ram_lines = [], []
    if overall_level != "OK" or full:
        disk_lines, ram_lines = top_users()

    if disk_lines:
        report += f"  top: {', '.join(disk_lines[:2])}\n"

    mem_used_gb = (mem_total - mem_avail) / 1e9
    mem_total_gb = mem_total / 1e9
    mem_avail_gb = mem_avail / 1e9
    swap_used_gb = (swap_total - swap_free) / 1e9
    swap_total_gb = swap_total / 1e9
    report += f"RAM: {mem_used_gb:.1f} of {mem_total_gb:.1f} GB used, {mem_avail_gb:.1f} GB available; swap {swap_used_gb:.1f} of {swap_total_gb:.1f} GB used\n"

    if ram_lines:
        report += f"  top: {', '.join(ram_lines[:2])}\n"

    print(report.rstrip())

    state_dir = os.path.expanduser(os.environ.get("JL_GUARD_STATE_DIR",
                                                    "~/.local/state/jl-guard"))
    Path(state_dir).mkdir(parents=True, exist_ok=True)
    with open(os.path.join(state_dir, "last.txt"), "w") as f:
        f.write(report)

    if notify:
        state_file = os.path.join(state_dir, "state.json")
        last = {"level": "OK", "epoch": 0}
        try:
            state = json.load(open(state_file))
            last = state.get("last", last)
        except (json.JSONDecodeError, OSError, FileNotFoundError):
            pass

        now = float(os.environ.get("JL_GUARD_NOW", time.time()))
        level_order = {"OK": 0, "WARN": 1, "CRIT": 2}
        last_level = last.get("level", "OK")
        is_worse = level_order.get(overall_level, 0) > level_order.get(last_level, 0)
        is_old = now - last.get("epoch", 0) > REPEAT_MIN * 60
        was_ok = last_level == "OK"
        should_notify = (overall_level != "OK" and (is_worse or is_old or was_ok))

        if should_notify:
            urgency = "-u critical" if overall_level == "CRIT" else "-u normal"
            cmd = os.environ.get("JL_GUARD_NOTIFY_CMD", "notify-send")
            notify_args = cmd.split() + [urgency, f"Jamilabs guard: {overall_level}",
                                        report.split("\n", 1)[1] if "\n" in report else ""]
            try:
                subprocess.run(notify_args, capture_output=True, timeout=5)
            except (OSError, subprocess.TimeoutExpired):
                pass

        if should_notify or overall_level == "OK":
            last_to_store = {"level": overall_level, "epoch": now}
            try:
                state = json.load(open(state_file))
            except (json.JSONDecodeError, OSError, FileNotFoundError):
                state = {"free": [], "last": {"level": "OK", "epoch": 0}}
            state["last"] = last_to_store
            with open(state_file, "w") as f:
                json.dump(state, f)

    return {"OK": 0, "WARN": 1, "CRIT": 2}[overall_level]

if __name__ == "__main__":
    sys.exit(main())
