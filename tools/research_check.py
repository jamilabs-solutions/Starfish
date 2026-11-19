#!/usr/bin/env python3
"""research_check v1.1: check every source quote of a research findings file against its live page."""
import html
import re
import sys
import urllib.request

ROW_RE = re.compile(r'^\| (F\d+) \| (\S+) \| "(.*)" \| .*\|$')
CITE_RE = re.compile(r'\[(F\d+)\]')
UA = 'jamilabs-source-check'
TAG_RE = re.compile(r'<[^>]*>')
SCRIPT_RE = re.compile(r'<script\b[^>]*>.*?</script>', re.IGNORECASE | re.DOTALL)
STYLE_RE = re.compile(r'<style\b[^>]*>.*?</style>', re.IGNORECASE | re.DOTALL)
WS_RE = re.compile(r'\s+')


def normalize(text):
    text = html.unescape(text)
    text = text.replace('\u00a0', ' ')
    text = text.replace('\u201c', '"').replace('\u201d', '"')
    text = text.replace('\u2018', "'").replace('\u2019', "'")
    text = WS_RE.sub(' ', text)
    return text.strip().lower()


def normalize_page(text):
    text = SCRIPT_RE.sub(' ', text)
    text = STYLE_RE.sub(' ', text)
    text = TAG_RE.sub(' ', text)
    return normalize(text)


def main():
    if len(sys.argv) != 2:
        print('Use: research_check.py <findings.md>', file=sys.stderr)
        sys.exit(2)

    path = sys.argv[1]
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()

    rows = []
    for line in lines:
        m = ROW_RE.match(line)
        if m:
            rows.append((m.group(1), m.group(2), m.group(3)))

    sources_line = None
    for i, line in enumerate(lines):
        if line.startswith('## Sources'):
            sources_line = i
            break

    cited = []
    seen = set()
    limit = sources_line if sources_line is not None else len(lines)
    for line in lines[:limit]:
        for m in CITE_RE.finditer(line):
            cid = m.group(1)
            if cid not in seen:
                seen.add(cid)
                cited.append(cid)

    row_ids = [r[0] for r in rows]
    cited_set = set(cited)

    results = []
    for rid, url, quote in rows:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=20) as resp:
                body = resp.read().decode('utf-8', errors='replace')
            norm_page = normalize_page(body)
            norm_quote = normalize(quote)
            status = 'FOUND' if norm_quote in norm_page else 'MISSING'
        except Exception:
            status = 'DEAD'
        results.append((rid, status, url))

    for cid in cited:
        if cid not in row_ids:
            results.append((cid, 'UNSOURCED', ''))

    for rid in row_ids:
        if rid not in cited_set:
            results.append((rid, 'UNUSED', ''))

    found = missing = dead = unsourced = unused = 0
    for rid, status, url in results:
        if status == 'FOUND':
            found += 1
        elif status == 'MISSING':
            missing += 1
        elif status == 'DEAD':
            dead += 1
        elif status == 'UNSOURCED':
            unsourced += 1
        elif status == 'UNUSED':
            unused += 1
        if url:
            print(f'{rid} {status} {url}')
        else:
            print(f'{status} {rid}')

    if found == 0 and missing == 0 and dead == 0 and unsourced == 0 and unused == 0:
        print(f'RESULT: NO-FINDINGS (found 0, missing 0, dead 0, unsourced 0, unused 0)')
        sys.exit(1)
    elif any(x != 0 for x in (missing, dead, unsourced, unused)):
        print(f'RESULT: FAIL (found {found}, missing {missing}, dead {dead}, unsourced {unsourced}, unused {unused})')
        sys.exit(1)
    else:
        print(f'RESULT: PASS (found {found}, missing {missing}, dead {dead}, unsourced {unsourced}, unused {unused})')
        sys.exit(0)


if __name__ == '__main__':
    main()