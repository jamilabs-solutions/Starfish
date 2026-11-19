#!/usr/bin/env python3
"""jl_runner v1.2: run a job and finish its run folder (plan P-001 M1)"""

import argparse
import re
import subprocess
import sys
import os
import glob
import math
import time
from pathlib import Path
from datetime import date
from datetime import datetime

def strip_ansi(text):
    """Remove ANSI escape codes from text."""
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

def read_kilo_txt(run_dir):
    """Read and strip ANSI from kilo.txt, return text or empty string."""
    path = Path(run_dir) / 'kilo.txt'
    if not path.exists():
        return ''
    return strip_ansi(path.read_text())

RESULT_WORDS = ('DONE', 'STOPPED', 'CLEAN', 'FINDINGS', 'COVERED', 'GAPS', 'PASS')
CLEAN_RESULTS = ('DONE', 'CLEAN', 'FINDINGS', 'COVERED', 'GAPS', 'PASS')
RESULT_RE = re.compile(r'AGENT: .*?RESULT: (' + '|'.join(RESULT_WORDS) + r')\b')

def extract_report(kilo_text):
    """Extract report from last AGENT: RESULT line. Returns (report_value, matching_text)."""
    lines = kilo_text.split('\n')
    matching_text = ''
    for i, line in enumerate(reversed(lines)):
        match = RESULT_RE.search(line)
        if match:
            # Template lines (e.g. "RESULT: DONE | STOPPED") are not reports
            if '|' in line[match.start(1):]:
                continue
            report = match.group(1)
            # Include from this line to end
            start_idx = len(lines) - i - 1
            matching_text = '\n'.join(lines[start_idx:])
            return report, matching_text
    return 'NONE', ''

def parse_checks_block(brief_text):
    """Parse CHECK/PASS-IF pairs from ## Machine checks block."""
    pairs = []
    lines = brief_text.split('\n')
    in_block = False
    i = 0
    while i < len(lines):
        if lines[i].startswith('## Machine checks'):
            in_block = True
            i += 1
            break
        i += 1

    if not in_block:
        return pairs

    while i < len(lines):
        if lines[i].startswith('## '):
            break
        if lines[i].startswith('CHECK '):
            command = lines[i][6:]
            if i + 1 < len(lines) and lines[i + 1].startswith('PASS-IF '):
                regex = lines[i + 1][8:]
                pairs.append((command, regex))
                i += 2
            else:
                i += 1
        else:
            i += 1

    return pairs

def run_checks(pairs, run_dir):
    """Run each check and return (checks_value, checks_text)."""
    checks_text = []
    has_failed = False
    has_no_findings = False

    for command, regex in pairs:
        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=run_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            output = result.stdout + result.stderr
            output_short = output.replace('\n', ' | ')[:300]
            checks_text.append(f'CHECK {command}')
            checks_text.append(f'OUTPUT {output_short}')

            if re.search(regex, output, re.MULTILINE):
                checks_text.append('RESULT PASS')
                if 'RESULT: NO-FINDINGS' in output:
                    has_no_findings = True
            else:
                checks_text.append('RESULT FAIL')
                has_failed = True
        except subprocess.TimeoutExpired:
            checks_text.append(f'CHECK {command}')
            checks_text.append('OUTPUT (timeout)')
            checks_text.append('RESULT FAIL')
            has_failed = True

    checks_value = 'NONE'
    if pairs:
        if has_failed:
            checks_value = 'FAIL'
        elif has_no_findings:
            checks_value = 'NO-FINDINGS'
        else:
            checks_value = 'PASS'

    return checks_value, '\n'.join(checks_text)

def toollog_check(report_text, session, db):
    """Every 'RAN <command>' line in the report must appear inside a bash command of the session log."""
    ran = [' '.join(m.group(1).split()) for m in re.finditer(r'^\s*RAN:?\s+(.+)$', report_text, re.MULTILINE)]
    if session == 'none':
        return True, f'TOOLLOG SKIPPED no session ({len(ran)} RAN lines)'
    watch = Path(__file__).with_name('kilo_watch.py')
    out = subprocess.run([sys.executable, '-I', str(watch), '--db', db, '--tools-of', session],
                         capture_output=True, text=True).stdout.splitlines()
    missing = [c for c in ran if not any(c in logged for logged in out)]
    lines = [f'TOOLLOG MISSING {c}' for c in missing]
    lines.append(f'TOOLLOG {"FAIL" if missing else "PASS"} {len(ran) - len(missing)}/{len(ran)}')
    return not missing, '\n'.join(lines)

def launch(args):
    """Run the vehicle, write kilo.txt, set exit, minutes and session on args."""
    run_dir = Path(args.dir)
    run_dir.mkdir(parents=True, exist_ok=True)
    prompt = Path(args.prompt_file).read_text()
    workdir = args.workdir or args.dir
    title = f"{args.brief} {args.model.split('/')[-1]} {datetime.now():%Y%m%d-%H%M%S}"
    if args.vehicle == 'kilo':
        found = sorted(glob.glob(os.path.expanduser('~/.vscode/extensions/kilocode.kilo-code-*/bin/kilo')))
        kilo = os.environ.get('JL_KILO') or (found[-1] if found else 'kilo')
        cmd, stdin = [kilo, 'run', '--dir', workdir, '--model', 'kilo/' + args.model, '--title', title, prompt], None
    else:
        cmd, stdin = [os.environ.get('JL_CLAUDE', 'claude'), '-p', '--model', args.model], prompt
    start = time.time()
    with open(run_dir / 'kilo.txt', 'w') as out:
        try:
            args.exit = subprocess.run(cmd, input=stdin, stdout=out, stderr=subprocess.STDOUT, text=True,
                                       cwd=workdir, timeout=args.timeout).returncode
        except subprocess.TimeoutExpired:
            args.exit = 124
    args.minutes = math.ceil((time.time() - start) / 60)
    args.session = 'none'
    if args.vehicle == 'kilo':
        watch = Path(__file__).with_name('kilo_watch.py')
        found_id = subprocess.run([sys.executable, '-I', str(watch), '--db', args.db, '--id-of', title],
                                  capture_output=True, text=True).stdout.strip()
        args.session = found_id if found_id and found_id != 'none' else 'none'

def main():
    parser = argparse.ArgumentParser(usage='%(prog)s finish|run [options]')
    parser.add_argument('command', help='Subcommand')
    parser.add_argument('--dir', required=True, help='Run directory')
    parser.add_argument('--brief-file', required=True, help='Brief file path')
    parser.add_argument('--plan', required=True, help='Plan ID')
    parser.add_argument('--brief', required=True, help='Brief ID')
    parser.add_argument('--role', required=True, help='Role')
    parser.add_argument('--model', required=True, help='Model')
    parser.add_argument('--vehicle', required=True, help='Vehicle')
    parser.add_argument('--exit', type=int, default=None, help='Exit code (finish)')
    parser.add_argument('--minutes', type=int, default=None, help='Minutes (finish)')
    parser.add_argument('--session', default='none', help='Session ID')
    parser.add_argument('--prompt-file', default=None, help='Prompt text (run)')
    parser.add_argument('--workdir', default=None, help='Where the agent works (run; default --dir)')
    parser.add_argument('--timeout', type=int, default=1800, help='Seconds (run)')
    parser.add_argument('--db', default=os.path.expanduser('~/.local/share/kilo/kilo.db'), help='Kilo db, read only through kilo_watch.py')

    try:
        args = parser.parse_args()
    except SystemExit:
        print('usage: jl_runner finish|run [options]', file=sys.stderr)
        sys.exit(2)

    if args.command not in ('finish', 'run') or (args.command == 'finish' and (args.exit is None or args.minutes is None)) \
            or (args.command == 'run' and (args.prompt_file is None or args.vehicle not in ('kilo', 'claude'))):
        print('usage: jl_runner finish|run [options]', file=sys.stderr)
        sys.exit(2)
    if args.command == 'run':
        launch(args)

    run_dir = Path(args.dir)
    brief_file = Path(args.brief_file)

    # Read kilo.txt
    kilo_text = read_kilo_txt(run_dir)
    report, report_text = extract_report(kilo_text)

    # Write report.md
    (run_dir / 'report.md').write_text(report_text)

    # Read brief and parse checks
    brief_text = brief_file.read_text() if brief_file.exists() else ''
    pairs = parse_checks_block(brief_text)
    checks_value, checks_text = run_checks(pairs, run_dir)
    toollog_ok, toollog_text = toollog_check(report_text, args.session, args.db)
    checks_text = checks_text + ('\n' if checks_text else '') + toollog_text
    if not toollog_ok:
        checks_value = 'FAIL'

    # Write checks.txt
    (run_dir / 'checks.txt').write_text(checks_text)

    # Determine cause
    exit_code = args.exit
    if exit_code == 124:
        cause = 'timeout'
    elif exit_code in (137, 143):
        cause = 'killed'
    elif exit_code != 0:
        cause = 'error'
    elif report == 'NONE':
        cause = 'no-report'
    else:
        cause = 'ok'

    # Determine clean
    clean = 'yes' if exit_code == 0 and report in CLEAN_RESULTS and checks_value == 'PASS' else 'no'

    # Calculate bytes and date
    kilo_path = run_dir / 'kilo.txt'
    bytes_val = kilo_path.stat().st_size if kilo_path.exists() else 0
    date_str = date.today().strftime('%Y-%m-%d')

    # Status line
    status_line = '\t'.join([
        date_str,
        args.plan,
        args.brief,
        args.role,
        args.model,
        args.vehicle,
        str(exit_code),
        cause,
        args.minutes.__str__(),
        str(bytes_val),
        report,
        checks_value,
        clean,
        args.session
    ])

    # Append to status.tsv and print
    status_file = run_dir / 'status.tsv'
    status_file.write_text(status_file.read_text() if status_file.exists() else '')
    with open(status_file, 'a') as f:
        f.write(status_line + '\n')

    print(status_line, flush=True)
    sys.exit(0)

if __name__ == '__main__':
    main()
