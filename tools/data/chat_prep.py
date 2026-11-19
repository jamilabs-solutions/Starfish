#!/usr/bin/env python3
"""Telegram Desktop export chat prep."""

import argparse
import hashlib
import json
import os
import re
import sys
from typing import Any


def flatten_text(text: Any) -> str:
    if isinstance(text, str):
        return text
    if isinstance(text, list):
        parts = []
        for item in text:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict) and "text" in item:
                parts.append(str(item["text"]))
        return "".join(parts)
    return ""


def sanitize(text: str) -> str:
    return re.sub(r"[\t\r\n]+", " ", text)


def chat_stem(path: str) -> str:
    return os.path.splitext(os.path.basename(path))[0]


def process_chat(path: str) -> tuple[str, str, list[dict], list[dict]]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    stem = chat_stem(path)
    title = data.get("name")
    title = "" if title is None else str(title)
    raw = data.get("messages") or []
    valid: list[dict] = []
    rejected: list[dict] = []
    for m in raw:
        if m.get("id") is None or m.get("date") is None:
            rejected.append(m)
        else:
            valid.append(m)
    valid.sort(key=lambda m: (str(m["date"]), m["id"]))
    return stem, title, valid, rejected


def build_messages(stem: str, valid: list[dict]) -> list[dict]:
    out: list[dict] = []
    for m in valid:
        mid = f"{stem}:{m['id']}"
        sender = m.get("from")
        if sender is None:
            sender = m.get("actor")
        sender = "" if sender is None else str(sender)
        reply_to = m.get("reply_to_message_id")
        reply_to = "" if reply_to is None else str(reply_to)
        media = ""
        if m.get("media_type") is not None:
            media = str(m["media_type"])
        elif m.get("photo") is not None:
            media = "photo"
        text = sanitize(flatten_text(m.get("text")))
        forwarded_from = m.get("forwarded_from")
        forwarded_from = "" if forwarded_from is None else str(forwarded_from)
        edited = m.get("edited")
        edited = "" if edited is None else str(edited)
        out.append(
            {
                "mid": mid,
                "chat": stem,
                "id": str(m["id"]),
                "time": str(m["date"]),
                "sender": sender,
                "reply_to": reply_to,
                "kind": str(m.get("type") or ""),
                "media": media,
                "text": text,
                "forwarded_from": forwarded_from,
                "edited": edited,
            }
        )
    return out


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir")
    parser.add_argument("exports", nargs="+")
    parser.add_argument("--size", type=int, default=100)
    parser.add_argument("--overlap", type=int, default=15)
    parser.add_argument("--batch", type=int, default=5)
    args = parser.parse_args(argv)

    exports = args.exports
    stems = [chat_stem(p) for p in exports]
    if len(set(stems)) != len(stems):
        sys.stderr.write("duplicate chat stem\n")
        return 2

    if args.size < 1 or args.overlap < 0 or args.overlap >= args.size:
        sys.stderr.write("bad size or overlap\n")
        return 2

    run_dir = args.run_dir
    batches_dir = os.path.join(run_dir, "batches")
    os.makedirs(batches_dir, exist_ok=True)

    chats: list[dict] = []
    rejected_all: list[dict] = []
    total_in = 0

    for path in exports:
        stem, title, valid, rejected = process_chat(path)
        messages = build_messages(stem, valid)
        chats.append(
            {"stem": stem, "title": title, "valid": valid, "messages": messages}
        )
        rejected_all.extend(rejected)
        total_in += len(valid) + len(rejected)

    total_out = sum(len(c["messages"]) for c in chats)
    total_rejected = len(rejected_all)

    with open(os.path.join(run_dir, "messages.tsv"), "w", encoding="utf-8") as f:
        f.write("mid\tchat\tid\ttime\tsender\treply_to\tkind\tmedia\ttext\tforwarded_from\tedited\n")
        for c in chats:
            for m in c["messages"]:
                f.write(
                    "\t".join(
                        [
                            m["mid"],
                            m["chat"],
                            m["id"],
                            m["time"],
                            m["sender"],
                            m["reply_to"],
                            m["kind"],
                            m["media"],
                            m["text"],
                            m["forwarded_from"],
                            m["edited"],
                        ]
                    )
                    + "\n"
                )

    with open(os.path.join(run_dir, "rejected.jsonl"), "w", encoding="utf-8") as f:
        for m in rejected_all:
            f.write(json.dumps(m, ensure_ascii=False) + "\n")

    with open(os.path.join(run_dir, "ledger.tsv"), "w", encoding="utf-8") as f:
        f.write("step\tin\tout\tset_aside\treason\n")
        f.write(
            f"parse\t{total_in}\t{total_out}\t{total_rejected}\tmissing id or date\n"
        )

    if total_in != total_out + total_rejected:
        print("LEDGER NOT BALANCED")
        return 1

    with open(os.path.join(run_dir, "scope.tsv"), "w", encoding="utf-8") as f:
        f.write("chat\ttitle\tmessages\tfirst\tlast\tsenders\tmedia\n")
        for c in chats:
            msgs = c["messages"]
            senders: dict[str, int] = {}
            media_counts: dict[str, int] = {}
            for m in msgs:
                senders[m["sender"]] = senders.get(m["sender"], 0) + 1
                if m["media"]:
                    media_counts[m["media"]] = media_counts.get(m["media"], 0) + 1
            senders_str = "".join(
                f"{name}={count};"
                for name, count in sorted(
                    senders.items(), key=lambda kv: (-kv[1], kv[0])
                )
            )
            media_str = "".join(
                f"{name}={count};"
                for name, count in sorted(media_counts.items(), key=lambda kv: kv[0])
            )
            first = msgs[0]["time"] if msgs else ""
            last = msgs[-1]["time"] if msgs else ""
            f.write(
                "\t".join(
                    [
                        c["stem"],
                        c["title"],
                        str(len(msgs)),
                        first,
                        last,
                        senders_str,
                        media_str,
                    ]
                )
                + "\n"
            )

    with open(os.path.join(run_dir, "sha256.txt"), "w", encoding="utf-8") as f:
        for path in exports:
            h = hashlib.sha256()
            with open(path, "rb") as src:
                for chunk in iter(lambda: src.read(65536), b""):
                    h.update(chunk)
            f.write(f"{h.hexdigest()}  {path}\n")

    windows: list[dict] = []
    wid = 1
    step = args.size - args.overlap
    for c in chats:
        msgs = c["messages"]
        n_total = len(msgs)
        i = 0
        while i < n_total:
            window = msgs[i : i + args.size]
            first_mid = window[0]["mid"]
            last_mid = window[-1]["mid"]
            windows.append(
                {
                    "id": f"w{wid:04d}",
                    "chat": c["stem"],
                    "first_mid": first_mid,
                    "last_mid": last_mid,
                    "n": len(window),
                    "messages": window,
                }
            )
            wid += 1
            if i + args.size >= n_total:
                break
            i += step

    with open(os.path.join(run_dir, "windows.tsv"), "w", encoding="utf-8") as f:
        f.write("window\tchat\tfirst_mid\tlast_mid\tn\n")
        for w in windows:
            f.write(
                f"{w['id']}\t{w['chat']}\t{w['first_mid']}\t{w['last_mid']}\t{w['n']}\n"
            )

    batches = (len(windows) + args.batch - 1) // args.batch
    for b in range(batches):
        chunk = windows[b * args.batch : (b + 1) * args.batch]
        path = os.path.join(batches_dir, f"batch-{b + 1:03d}.md")
        with open(path, "w", encoding="utf-8") as f:
            for wi, w in enumerate(chunk):
                if wi > 0:
                    f.write("\n")
                f.write(f"## WINDOW {w['id']}\n")
                for m in w["messages"]:
                    line = (
                        f"{m['mid']} | {m['time']} | {m['sender']} | "
                        f"reply:{m['reply_to']} | {m['text']}"
                    )
                    if m["forwarded_from"]:
                        line += f" [forwarded from: {m['forwarded_from']}]"
                    if m["edited"]:
                        line += " [edited]"
                    if m["media"]:
                        line += f" [media: {m['media']}]"
                    f.write(line + "\n")

    print(
        f"OK messages={total_out} rejected={total_rejected} "
        f"windows={len(windows)} batches={batches}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))