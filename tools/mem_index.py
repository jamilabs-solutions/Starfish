#!/usr/bin/env python3
"""mem_index v1.0 · P-006 W2"""

import argparse
import re
import sqlite3
import sys
from pathlib import Path


ROW_RE = re.compile(r'^\| \d{4}-\d{2}-\d{2} \|')


def parse_file(filepath, rel, kind):
    content = filepath.read_text()
    title = None
    for line in content.splitlines():
        if line.startswith('# '):
            title = line[2:].strip()
            break
    if title is None:
        title = filepath.name
    return [(rel, kind, title, content)]


def parse_sections(filepath, rel, kind):
    lines = filepath.read_text().splitlines()
    docs = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('### '):
            heading = line[4:].strip()
            body = [line]
            i += 1
            while i < len(lines) and not lines[i].startswith('#'):
                body.append(lines[i])
                i += 1
            docs.append((f"{rel}#{heading}", kind, heading, '\n'.join(body)))
        else:
            i += 1
    return docs


def parse_rows(filepath, rel, kind):
    lines = filepath.read_text().splitlines()
    docs = []
    for i, line in enumerate(lines, start=1):
        if ROW_RE.match(line):
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            title = cells[1][:80] if len(cells) > 1 else ''
            docs.append((f"{rel}:{i}", kind, title, line))
    return docs


def load_docs(base, roots_path):
    docs = []
    with open(roots_path) as f:
        for raw in f:
            line = raw.rstrip('\n')
            if not line.strip() or line.startswith('#'):
                continue
            parts = line.split('\t')
            if len(parts) != 3:
                continue
            glob, parser, kind = parts
            files = sorted(Path(base).glob(glob))
            if not files:
                print(f"NO FILES: {glob}", file=sys.stderr)
                continue
            for fpath in files:
                rel = str(fpath.relative_to(base)).replace('\\', '/')
                if parser == 'file':
                    docs.extend(parse_file(fpath, rel, kind))
                elif parser == 'sections':
                    docs.extend(parse_sections(fpath, rel, kind))
                elif parser == 'rows':
                    docs.extend(parse_rows(fpath, rel, kind))
    return docs


def build_db(docs):
    conn = sqlite3.connect(':memory:')
    conn.execute(
        "CREATE VIRTUAL TABLE docs USING fts5("
        "id UNINDEXED, kind UNINDEXED, title, text, "
        "tokenize='porter unicode61')"
    )
    conn.executemany(
        "INSERT INTO docs (id, kind, title, text) VALUES (?, ?, ?, ?)", docs
    )
    return conn


def fmt(s):
    return s.replace('\t', ' ').replace('\n', ' ')


def cmd_list(docs):
    for d in docs:
        print(f"{d[0]}\t{d[1]}\t{fmt(d[2])}")
    print(f"DOCS: {len(docs)}")


def cmd_recall(conn, words, top):
    tokens = re.findall(r'[a-z0-9]+', ' '.join(words).lower())
    if not tokens:
        print("NO MATCH")
        return
    query = ' OR '.join('"%s"' % t for t in tokens)
    rows = conn.execute(
        "SELECT id, kind, title, text, bm25(docs, 0, 0, 3.0, 1.0) AS score "
        "FROM docs WHERE docs MATCH ?",
        (query,)
    ).fetchall()
    if not rows:
        print("NO MATCH")
        return
    scored = []
    for r in rows:
        score = r[4]
        if '[checked]' in r[3]:
            score *= 2
        scored.append((score, r[0], r[1], r[2]))
    scored.sort(key=lambda x: (x[0], x[1]))
    for s, rid, kind, title in scored[:top]:
        print(f"{rid}\t{kind}\t{fmt(title)}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--roots', default=None)
    parser.add_argument('--base', default=None)
    sub = parser.add_subparsers(dest='cmd', required=True)

    sub.add_parser('list')

    p_recall = sub.add_parser('recall')
    p_recall.add_argument('--top', type=int, default=3)
    p_recall.add_argument('words', nargs='+')

    args = parser.parse_args()

    prog = Path(__file__).resolve()
    prog_dir = prog.parent
    base = args.base if args.base else str(prog_dir.parent)
    if args.roots is None:
        roots = str(prog_dir / 'mem_roots.tsv')
    else:
        roots = str(Path(args.roots).resolve())

    docs = load_docs(base, roots)
    conn = build_db(docs)

    if args.cmd == 'list':
        cmd_list(docs)
    elif args.cmd == 'recall':
        cmd_recall(conn, args.words, args.top)


if __name__ == '__main__':
    main()