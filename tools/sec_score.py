#!/usr/bin/env python3
"""sec_score v1.1: score a security report against the key (plan P-003 S3)"""
import os, re, sys
WHERE_RE = re.compile(r'WHERE:\s*`?([^\s`:]+):(\d+)')
def die(m):
    sys.stderr.write("ERROR: " + m + "\n"); sys.exit(2)
def main():
    if len(sys.argv) != 4: die("usage")
    fpath, app, key = sys.argv[1], sys.argv[2], sys.argv[3]
    wpath = os.path.join(key, 'where.tsv')
    if not os.path.isfile(fpath): die("findings file missing")
    if not os.path.isfile(wpath): die("where.tsv missing")
    rows = []
    with open(wpath, newline='') as fh:
        next(fh, None)
        for line in fh:
            p = line.rstrip('\n').split('\t')
            if len(p) >= 6 and p[0] == app:
                rows.append((p[1], p[2], p[3], int(p[4]), int(p[5])))
    if not rows: die("no rows for app")
    findings = []
    with open(fpath, newline='') as fh:
        for line in fh:
            m = WHERE_RE.search(line)
            if m:
                p = m.group(1)
                if p.startswith('./'): p = p[2:]
                findings.append((p, int(m.group(2))))
    hit = {}
    open_hit = {}
    unscored = []
    for fpath2, ln in findings:
        hs = [rid for rid, st, fl, s, e in rows
              if (fpath2 == fl or fpath2.endswith('/' + fl)) and s <= ln <= e]
        if hs:
            for h in hs:
                hit.setdefault(h, True)
                if any(rid == h and st == 'open' for rid, st, fl, s, e in rows):
                    open_hit.setdefault(h, True)
        else: unscored.append(fpath2 + ':' + str(ln))
    open_ids = sorted({r[0] for r in rows if r[1] == 'open'})
    total = len(open_ids)
    found_ids = sorted(hit.keys())
    missed = sorted(set(open_ids) - set(found_ids))
    fa = sorted({r[0] for r in rows if r[1] in ('closed', 'safe') and r[0] in hit})
    def lst(x): return ' '.join(x) if x else 'None'
    print("FINDINGS " + str(len(findings)))
    print("FOUND " + str(len(open_hit)) + "/" + str(total))
    print("MISSED: " + lst(missed))
    print("FALSE ALARMS " + str(len(fa)) + ": " + lst(fa))
    print("UNSCORED " + str(len(unscored)) + ": " + lst(unscored))
if __name__ == '__main__':
    main()