#!/usr/bin/env python3
"""ledger v1.2: replay old run folders into an events file; append status lines to events (plan P-001 M1-M2)."""
import argparse, glob, os, re, time

MODELS = {"nemotron-3.5": "nvidia/nemotron-3.5-super-vl:free", "nemotron-3": "nvidia/nemotron-3-ultra-550b-a55b:free", "dots-3": "dots-studio/dots-3-note-preview:free"}
HEADER = "date\tproject\tbrief\tmodel\tkind\troute\tmin\ttokens\tok\tnote"
ANSI = re.compile(r"\x1b\[[0-9;]*m")
REPORT_RE = re.compile(r"AGENT: .* RESULT: (DONE|STOPPED)")


def load_status(root):
    status = {}
    for path in sorted(glob.glob(os.path.join(root, "status*.tsv"))):
        with open(path) as f:
            for raw in f:
                line = raw.rstrip("\n")
                if line.startswith("#"):
                    continue
                fld = line.split("\t")
                if len(fld) < 5:
                    continue
                status[fld[0] + "-" + fld[1]] = (fld[2], fld[3], fld[5] if len(fld) >= 6 else "none")
    return status


def load_checks(root):
    checks = {}
    path = os.path.join(root, "r1-check.tsv")
    if os.path.exists(path):
        with open(path) as f:
            for raw in f:
                fld = raw.rstrip("\n").split("\t")
                if len(fld) >= 2:
                    checks[fld[0]] = fld[1]
    return checks


def read_report(folder):
    path = os.path.join(folder, "kilo.txt")
    with open(path, errors="replace") as f:
        text = ANSI.sub("", f.read())
    report = "NONE"
    for line in text.splitlines():
        if "DONE | STOPPED" in line:
            continue
        m = REPORT_RE.search(line)
        if m:
            report = m.group(1)
    return report


def classify_checks(folder, checks):
    if not os.path.exists(os.path.join(folder, "research_check.py")):
        return "NONE"
    c = checks.get(os.path.basename(folder), "")
    if c.startswith("NO-FINDINGS") or "PASS (found 0," in c:
        return "NO-FINDINGS"
    if c.startswith("RESULT: PASS"):
        return "PASS"
    if c.startswith("RESULT: FAIL"):
        return "FAIL"
    return "NONE"


def cause_of(exit_code, report):
    if exit_code == 124:
        return "timeout"
    if exit_code in (137, 143):
        return "killed"
    if exit_code != 0:
        return "error"
    if report == "NONE":
        return "no-report"
    return "ok"


def replay(root, events):
    status = load_status(root)
    checks = load_checks(root)
    known = set()
    existed = os.path.exists(events)
    if existed:
        with open(events) as f:
            for raw in f:
                fld = raw.rstrip("\n").split("\t")
                if len(fld) >= 4:
                    known.add((fld[2], fld[3]))
    else:
        with open(events, "w") as f:
            f.write(HEADER + "\n")
    runs = os.path.join(root, "runs")
    folders = 0
    clean_total = 0
    no_report = 0
    done_fail = 0
    no_findings = 0
    checks_none = 0
    by_model = {}
    for name in sorted(os.listdir(runs)):
        folder = os.path.join(runs, name)
        if not os.path.isdir(folder):
            continue
        folders += 1
        id_, short = name.split("-", 1)
        brief = "P-002-" + id_
        model = MODELS[short]
        report = read_report(folder)
        cchecks = classify_checks(folder, checks)
        exit_code, minutes, session = status.get(name, ("-", "-", "none"))
        exit_code = int(exit_code) if exit_code != "-" else -1
        cause = cause_of(exit_code, report)
        clean = report == "DONE" and cchecks == "PASS"
        if clean:
            clean_total += 1
        if report == "NONE":
            no_report += 1
        if report == "DONE" and cchecks == "FAIL":
            done_fail += 1
        if cchecks == "NO-FINDINGS":
            no_findings += 1
        if cchecks == "NONE":
            checks_none += 1
        by_model.setdefault(short, [0, 0])
        by_model[short][1] += 1
        if clean:
            by_model[short][0] += 1
        date = time.strftime("%Y-%m-%d", time.localtime(os.path.getmtime(os.path.join(folder, "kilo.txt"))))
        if (brief, model) in known:
            continue
        note = "report=%s checks=%s cause=%s %s" % (report, cchecks, cause, session)
        ok = "yes" if clean else "no"
        with open(events, "a") as f:
            f.write("%s\tcompany\t%s\t%s\tATTEMPT\tkilo-headless\t%s\t-\t%s\t%s\n" % (date, brief, model, minutes, ok, note))
            if cause == "no-report":
                f.write("%s\tcompany\t%s\t%s\tDEVIATION\tkilo-headless\t%s\t-\tno\tno report\n" % (date, brief, model, minutes))
            elif report == "DONE" and cchecks == "FAIL":
                f.write("%s\tcompany\t%s\t%s\tDEVIATION\tkilo-headless\t%s\t-\tno\tDONE with a failing check\n" % (date, brief, model, minutes))
    summary = "clean %d/%d · no-report %d · DONE+FAIL %d · NO-FINDINGS %d · checks NONE %d" % (clean_total, folders, no_report, done_fail, no_findings, checks_none)
    print(summary)
    ranked = sorted(by_model.items(), key=lambda kv: (-kv[1][0], kv[0]))
    print(" · ".join("%s %d/%d" % (k, v[0], v[1]) for k, v in ranked))


def append(root, events_dir):
    rows = 0
    folders_contributed = 0
    for name in sorted(os.listdir(root)):
        folder = os.path.join(root, name)
        if not os.path.isdir(folder):
            continue
        status_path = os.path.join(folder, "status.tsv")
        if not os.path.exists(status_path):
            continue
        last_line = None
        with open(status_path) as f:
            for raw in f:
                line = raw.rstrip("\n")
                if not line or line.startswith("#"):
                    continue
                fld = line.split("\t")
                if len(fld) == 14:
                    last_line = (line, fld)
        if last_line is None:
            continue
        line_text, fld = last_line
        role = fld[3]
        events_path = os.path.join(events_dir, role + ".events.tsv")
        known = set()
        if not os.path.exists(events_path):
            with open(events_path, "w") as f:
                f.write(HEADER + "\n")
        else:
            with open(events_path) as f:
                for raw in f:
                    efld = raw.rstrip("\n").split("\t")
                    if len(efld) >= 4:
                        known.add((efld[2], efld[3]))
        date, plan, brief, role, model, vehicle, exit_code, cause, minutes, bytess, report, checks, clean, session = fld
        if (brief, model) in known:
            continue
        folders_contributed += 1
        note = "report=%s checks=%s cause=%s %s" % (report, checks, cause, session)
        ok = "yes" if clean == "yes" else "no"
        with open(events_path, "a") as f:
            f.write("%s\tcompany\t%s\t%s\tATTEMPT\t%s\t%s\t-\t%s\t%s\n" % (date, brief, model, vehicle, minutes, ok, note))
            rows += 1
            if cause == "no-report":
                f.write("%s\tcompany\t%s\t%s\tDEVIATION\t%s\t%s\t-\tno\tno report\n" % (date, brief, model, vehicle, minutes))
                rows += 1
            elif report == "DONE" and checks == "FAIL":
                f.write("%s\tcompany\t%s\t%s\tDEVIATION\t%s\t%s\t-\tno\tDONE with a failing check\n" % (date, brief, model, vehicle, minutes))
                rows += 1
    print("appended %d rows from %d folders" % (rows, folders_contributed))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    rp = sub.add_parser("replay")
    rp.add_argument("root")
    rp.add_argument("--events", required=True)
    ap_p = sub.add_parser("append")
    ap_p.add_argument("root")
    ap_p.add_argument("--events-dir", required=True)
    args = ap.parse_args()
    if args.cmd == "replay":
        replay(args.root, args.events)
    elif args.cmd == "append":
        append(args.root, args.events_dir)


if __name__ == "__main__":
    main()