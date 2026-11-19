#!/usr/bin/env python3
"""Chat check: validate events against a prepared run."""

import argparse
import os
import sys
from typing import Any

HEADER = (
    "event\twindow\tfirst_mid\tlast_mid\tdate\tactor\ttarget\ttype\tside\twhat\tquote"
)

NONE_TYPES = {
    "instruction",
    "guidance",
    "praise",
    "accusation",
    "correction",
    "scolding",
    "insult",
    "refusal",
    "dismissal",
    "promise",
    "broken_promise",
    "contradiction",
    "apology",
    "mistake",
    "work_fact",
    "other",
}
SIDES = {"supports_asker", "against_asker", "neutral"}


def collapse(text: str) -> str:
    return " ".join(text.split())


def load_messages(run_dir: str) -> tuple[dict, dict, dict]:
    messages: dict[str, dict] = {}
    chat_order: dict[str, list[str]] = {}
    chat_index: dict[str, int] = {}
    path = os.path.join(run_dir, "messages.tsv")
    with open(path, "r", encoding="utf-8") as f:
        f.readline()
        for line in f:
            line = line.rstrip("\n")
            if line == "":
                continue
            parts = line.split("\t")
            if len(parts) < 9:
                continue
            mid, chat, mid_id, time, sender, reply_to, kind, media, text = parts[:9]
            messages[mid] = {
                "mid": mid,
                "chat": chat,
                "id": mid_id,
                "time": time,
                "sender": sender,
                "reply_to": reply_to,
                "kind": kind,
                "media": media,
                "text": text,
            }
            chat_order.setdefault(chat, []).append(mid)
            chat_index[mid] = len(chat_order[chat]) - 1
    return messages, chat_order, chat_index


def load_windows(run_dir: str) -> dict[str, list[str]]:
    windows: dict[str, list[str]] = {}
    path = os.path.join(run_dir, "windows.tsv")
    with open(path, "r", encoding="utf-8") as f:
        f.readline()
        for line in f:
            line = line.rstrip("\n")
            if line == "":
                continue
            parts = line.split("\t")
            windows[parts[0]] = parts
    return windows


def load_events(path: str) -> list[dict]:
    rows: list[dict] = []
    with open(path, "r", encoding="utf-8") as f:
        first = f.readline().rstrip("\n")
        if first != HEADER:
            # handled by caller; store marker
            pass
        for line in f:
            line = line.rstrip("\n")
            if line == "":
                continue
            parts = line.split("\t")
            ncols = len(parts)
            while len(parts) < 11:
                parts.append("")
            rows.append(
                {
                    "event": parts[0],
                    "window": parts[1],
                    "first_mid": parts[2],
                    "last_mid": parts[3],
                    "date": parts[4],
                    "actor": parts[5],
                    "target": parts[6],
                    "type": parts[7],
                    "side": parts[8],
                    "what": parts[9],
                    "quote": parts[10],
                    "_ncols": ncols,
                    "_header_ok": first == HEADER,
                }
            )
    # attach header check via module global? Instead check in do_check
    return rows


def do_check(run_dir: str, events_path: str) -> int:
    with open(events_path, "r", encoding="utf-8") as f:
        first_line = f.readline().rstrip("\n")
    if first_line != HEADER:
        print("BAD HEADER")
        return 1
    messages, chat_order, chat_index = load_messages(run_dir)
    windows = load_windows(run_dir)
    rows = load_events(events_path)

    covered: set[str] = set()
    events_count = 0
    quotes_ok = 0
    quotes_bad = 0
    failed = False

    for row in rows:
        wid = row["window"]
        if wid not in windows:
            print(f"BAD {row['event']} unknown window")
            failed = True
            continue
        covered.add(wid)

        if row["type"] == "NONE":
            continue

        events_count += 1

        if row.get("_ncols", 11) != 11:
            print(f"BAD {row['event']} columns")
            failed = True
            continue

        if row["type"] not in NONE_TYPES:
            print(f"BAD {row['event']} unknown type")
            failed = True
        if row["side"] not in SIDES:
            print(f"BAD {row['event']} unknown side")
            failed = True

        first = row["first_mid"]
        last = row["last_mid"]
        mid_ok = True
        if first not in messages:
            print(f"BAD {row['event']} first_mid not in messages.tsv")
            mid_ok = False
        if last not in messages:
            print(f"BAD {row['event']} last_mid not in messages.tsv")
            mid_ok = False

        quote_ok = False
        if mid_ok:
            if messages[first]["chat"] != messages[last]["chat"]:
                print(f"BAD {row['event']} different chats")
                failed = True
            else:
                fi = chat_index[first]
                li = chat_index[last]
                if li < fi:
                    print(f"BAD {row['event']} last is before first")
                    failed = True
                else:
                    quote = row["quote"]
                    if quote.strip() == "":
                        print(f"BAD {row['event']} quote empty")
                        failed = True
                    else:
                        chat = messages[first]["chat"]
                        texts = [
                            messages[m]["text"]
                            for m in chat_order[chat][fi : li + 1]
                        ]
                        joined = collapse(" ".join(texts))
                        if collapse(quote) in joined:
                            quote_ok = True
                        else:
                            print(f"BAD {row['event']} quote not found")
                            failed = True
        else:
            failed = True
            if row["quote"].strip() == "":
                print(f"BAD {row['event']} quote empty")

        # outside window check
        if mid_ok and first in messages and last in messages:
            wparts = windows[wid]
            wf = wparts[2]
            wl = wparts[3]
            if messages[first]["chat"] == messages[last]["chat"] == messages[wf]["chat"]:
                fi = chat_index[first]
                li = chat_index[last]
                wfi = chat_index[wf]
                wli = chat_index[wl]
                if fi < wfi or fi > wli or li < wfi or li > wli:
                    print(f"BAD {row['event']} outside window")
                    failed = True

        if quote_ok:
            quotes_ok += 1
        else:
            quotes_bad += 1

    for wid in windows:
        if wid not in covered:
            print(f"MISSING {wid}")
            failed = True

    print(f"WINDOWS {len(covered)} of {len(windows)}")
    print(f"EVENTS {events_count}")
    print(f"QUOTES ok {quotes_ok} bad {quotes_bad}")

    return 1 if failed else 0


def do_diff(run_dir: str, a_path: str, b_path: str) -> int:
    messages, chat_order, chat_index = load_messages(run_dir)

    def load_rows(path: str) -> list[dict]:
        rows = load_events(path)
        return [r for r in rows if r["type"] != "NONE"]

    def get_range(row: dict) -> Any:
        fi = chat_index.get(row["first_mid"])
        li = chat_index.get(row["last_mid"])
        if fi is None or li is None:
            return None
        if messages[row["first_mid"]]["chat"] != messages[row["last_mid"]]["chat"]:
            return None
        return (messages[row["first_mid"]]["chat"], fi, li)

    def matches(a: dict, b: dict) -> bool:
        if a["type"] != b["type"]:
            return False
        ra = get_range(a)
        rb = get_range(b)
        if ra is None or rb is None:
            return False
        if ra[0] != rb[0]:
            return False
        a0, a1 = ra[1], ra[2]
        b0, b1 = rb[1], rb[2]
        return a0 <= b1 and b0 <= a1

    rows_a = load_rows(a_path)
    rows_b = load_rows(b_path)

    only_a: list[dict] = []
    only_b: list[dict] = []
    both = 0

    for ra in rows_a:
        if any(matches(ra, rb) for rb in rows_b):
            both += 1
        else:
            only_a.append(ra)

    for rb in rows_b:
        if any(matches(ra, rb) for ra in rows_a):
            continue
        only_b.append(rb)

    def write_rows(path: str, rows: list[dict]) -> None:
        with open(path, "w", encoding="utf-8") as f:
            f.write(HEADER + "\n")
            for r in rows:
                f.write(
                    "\t".join(
                        [
                            r["event"],
                            r["window"],
                            r["first_mid"],
                            r["last_mid"],
                            r["date"],
                            r["actor"],
                            r["target"],
                            r["type"],
                            r["side"],
                            r["what"],
                            r["quote"],
                        ]
                    )
                    + "\n"
                )

    write_rows(os.path.join(run_dir, "only_a.tsv"), only_a)
    write_rows(os.path.join(run_dir, "only_b.tsv"), only_b)

    print(f"BOTH {both} ONLY_A {len(only_a)} ONLY_B {len(only_b)}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir")
    parser.add_argument("events", nargs="?")
    parser.add_argument("--diff", nargs=2, metavar=("A", "B"))
    args = parser.parse_args(argv)

    if args.diff:
        return do_diff(args.run_dir, args.diff[0], args.diff[1])
    if args.events is None:
        sys.stderr.write("events file required\n")
        return 2
    return do_check(args.run_dir, args.events)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))