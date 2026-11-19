#!/usr/bin/env python3
"""inbox v1.0: status lines of a plan's run folders (plan P-001 M1)"""

import sys
import os
import argparse
from pathlib import Path
from datetime import datetime

def get_status_tsv_lines(root_dir, plan):
    """Find all status.tsv files up to 3 folders deep and extract last valid line from each."""
    plan_path = Path(root_dir) / plan

    if not plan_path.exists():
        return []

    results = []

    # Walk up to 3 levels deep
    for fpath in plan_path.rglob('status.tsv'):
        # Check depth (excluding the filename itself)
        depth = len(fpath.relative_to(plan_path).parts) - 1
        if depth > 3:
            continue

        try:
            with open(fpath, 'r') as f:
                lines = f.readlines()

            # Find last non-blank, non-# line with exactly 14 columns
            for line in reversed(lines):
                line = line.rstrip('\n')
                if not line or line.startswith('#'):
                    continue

                cols = line.split('\t')
                if len(cols) == 14:
                    # Get file modification time
                    mtime = os.path.getmtime(fpath)
                    results.append({
                        'line': line,
                        'date': cols[0],
                        'mtime': mtime,
                        'fpath': fpath
                    })
                    break
        except Exception:
            pass

    return results

def format_output(results):
    """Format results as per specification."""
    if not results:
        return []

    # Sort by date (column 1) descending, then by mtime descending
    sorted_results = sorted(
        results,
        key=lambda x: (x['date'], x['mtime']),
        reverse=True
    )

    output_lines = []
    for item in sorted_results:
        cols = item['line'].split('\t')
        # Reconstruct: date brief role model vehicle exit cause minutes report checks clean
        date = cols[0]
        brief = cols[2]
        role = cols[3]
        model = cols[4]
        vehicle = cols[5]
        exit_code = cols[6]
        cause = cols[7]
        minutes = cols[8]
        report = cols[10]
        checks = cols[11]
        clean = cols[12]

        line = f"{date} {brief} {role} {model} {vehicle} exit={exit_code} {cause} {minutes}min report={report} checks={checks} clean={clean}"
        output_lines.append(line)

    return output_lines

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('plan', help='Plan name')
    parser.add_argument('--root', default=str(Path(__file__).resolve().parents[2] / 'jl-runs'), help='Root directory')

    args = parser.parse_args()

    results = get_status_tsv_lines(args.root, args.plan)
    output = format_output(results)

    print(f"INBOX {args.plan}: {len(results)} runs")
    for line in output:
        print(line)

if __name__ == '__main__':
    main()
