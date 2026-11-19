#!/usr/bin/env python3
"""
leakcheck v1.2: private markers in the agency's public files (AG-001).
"""

import sys
import os
import re
import fnmatch
import subprocess
from pathlib import Path
from typing import List, Tuple, Optional


def run_git(args: List[str], cwd: Optional[Path] = None) -> str:
    result = subprocess.run(["git"] + args, capture_output=True, text=True, cwd=cwd)
    return result.stdout.strip()


def get_root() -> Path:
    output = run_git(["rev-parse", "--show-toplevel"])
    return Path(output)


def read_lines(path: Path) -> List[str]:
    if not path.exists():
        return []
    content = path.read_text(encoding="utf-8")
    lines = []
    for line in content.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            lines.append(stripped)
    return lines


def load_manifest(root: Path) -> Tuple[List[str], List[str]]:
    manifest_path = Path(os.environ.get("JL_MANIFEST", root / "agency.manifest"))
    lines = read_lines(manifest_path)
    include_patterns = [l for l in lines if not l.startswith("!")]
    exclude_patterns = [l[1:] for l in lines if l.startswith("!")]
    return include_patterns, exclude_patterns


def load_markers(root: Path) -> List[Tuple[str, re.Pattern]]:
    markers_path = Path(os.environ.get("JL_MARKERS", root / "memory" / "private-markers.txt"))
    if not markers_path.exists():
        print(f"leakcheck: no markers file {markers_path}", file=sys.stderr)
        sys.exit(2)
    lines = read_lines(markers_path)
    markers = []
    for line in lines:
        if line.startswith("word:"):
            text = line[5:]
            pattern = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(text) + r"(?![A-Za-z0-9_])", re.I)
            markers.append((line, pattern))
        elif line.startswith("re:"):
            regex = line[3:]
            pattern = re.compile(regex)
            markers.append((line, pattern))
    return markers


def load_swaps(root: Path) -> List[Tuple[str, str]]:
    markers_path = Path(os.environ.get("JL_MARKERS", root / "memory" / "private-markers.txt"))
    if not markers_path.exists():
        return []
    lines = read_lines(markers_path)
    swaps = []
    for line in lines:
        if line.startswith("swap:"):
            rest = line[5:]
            if "=>" in rest:
                text, public = rest.split("=>", 1)
                swaps.append((text, public))
    return swaps


def load_allows(root: Path) -> List[Tuple[str, str]]:
    markers_path = Path(os.environ.get("JL_MARKERS", root / "memory" / "private-markers.txt"))
    if not markers_path.exists():
        return []
    lines = read_lines(markers_path)
    allows = []
    for line in lines:
        if line.startswith("allow:"):
            rest = line[6:]
            if " " in rest:
                pattern, label = rest.split(" ", 1)
                allows.append((pattern, label))
    return allows


def apply_swaps(content: str, swaps: List[Tuple[str, str]]) -> str:
    for text, public in swaps:
        content = content.replace(text, public)
    return content


def filter_allows(hits: List[Tuple[int, str]], rel_path: Path, root: Path, allows: List[Tuple[str, str]]) -> List[Tuple[int, str]]:
    if not allows:
        return hits
    rel_str = str(rel_path.relative_to(root))
    filtered = []
    for line_num, label in hits:
        allowed = False
        for pattern, allow_label in allows:
            if fnmatch.fnmatch(rel_str, pattern) and label == allow_label:
                allowed = True
                break
        if not allowed:
            filtered.append((line_num, label))
    return filtered


def is_public(path: Path, root: Path, include_patterns: List[str], exclude_patterns: List[str]) -> bool:
    rel_path = path.relative_to(root)
    rel_str = str(rel_path)
    matched_include = any(fnmatch.fnmatch(rel_str, pat) for pat in include_patterns)
    if not matched_include:
        return False
    matched_exclude = any(fnmatch.fnmatch(rel_str, pat) for pat in exclude_patterns)
    return not matched_exclude


def has_nul_byte(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            chunk = f.read(8000)
            return b"\x00" in chunk
    except Exception:
        return True


def scan_file(path: Path, root: Path, markers: List[Tuple[str, re.Pattern]]) -> List[Tuple[int, str]]:
    hits = []
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return hits
    for i, line in enumerate(content.splitlines(), 1):
        for label, pattern in markers:
            if pattern.search(line):
                hits.append((i, label))
    return hits


def get_manifest_files(root: Path) -> List[Path]:
    output = run_git(["ls-files"], cwd=root)
    if not output:
        return []
    return [root / p for p in output.splitlines()]


def get_staged_files(root: Path) -> List[Path]:
    output = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACM"], cwd=root)
    if not output:
        return []
    return [root / p for p in output.splitlines()]


def get_staged_content(root: Path, rel_path: Path) -> str:
    output = run_git(["show", f":{rel_path}"], cwd=root)
    return output


def main() -> int:
    root = get_root()
    include_patterns, exclude_patterns = load_manifest(root)
    markers = load_markers(root)
    swaps = load_swaps(root)
    allows = load_allows(root)

    args = sys.argv[1:]
    if not args:
        print("Usage: leakcheck.py --manifest | --staged | <file> [<file> ...]", file=sys.stderr)
        return 2

    total_hits = 0
    files_with_hits = 0
    files_scanned = 0

    if args[0] == "--manifest":
        files = get_manifest_files(root)
        for f in files:
            if not is_public(f, root, include_patterns, exclude_patterns):
                continue
            if has_nul_byte(f):
                continue
            files_scanned += 1
            content = f.read_text(encoding="utf-8", errors="replace")
            content = apply_swaps(content, swaps)
            hits = []
            for i, line in enumerate(content.splitlines(), 1):
                for label, pattern in markers:
                    if pattern.search(line):
                        hits.append((i, label))
            hits = filter_allows(hits, f, root, allows)
            if hits:
                files_with_hits += 1
                rel = f.relative_to(root)
                for line_num, label in hits:
                    print(f"{rel}:{line_num}: {label}")
                    total_hits += 1

    elif args[0] == "--staged":
        files = get_staged_files(root)
        new_leak_found = False
        for f in files:
            if not is_public(f, root, include_patterns, exclude_patterns):
                continue
            files_scanned += 1
            rel = f.relative_to(root)
            staged_content = get_staged_content(root, rel)
            staged_content = apply_swaps(staged_content, swaps)
            staged_hits = []
            for i, line in enumerate(staged_content.splitlines(), 1):
                for label, pattern in markers:
                    for _ in pattern.finditer(line):
                        staged_hits.append((i, label))
            staged_hits = filter_allows(staged_hits, f, root, allows)
            if staged_hits:
                files_with_hits += 1
                for line_num, label in staged_hits:
                    print(f"{rel}:{line_num}: {label}")
                    total_hits += 1
            head_output = run_git(["show", f"HEAD:{rel}"])
            head_hits = []
            if head_output:
                head_output = apply_swaps(head_output, swaps)
                for i, line in enumerate(head_output.splitlines(), 1):
                    for label, pattern in markers:
                        for _ in pattern.finditer(line):
                            head_hits.append((i, label))
            head_hits = filter_allows(head_hits, f, root, allows)
            if len(staged_hits) > len(head_hits):
                new_leak_found = True
                print(f"NEW: {rel} has {len(staged_hits)} markers, HEAD had {len(head_hits)}.")
        if new_leak_found:
            print(f"LEAKCHECK: {total_hits} hits in {files_with_hits} of {files_scanned} files")
            return 1
        print(f"LEAKCHECK: {total_hits} hits in {files_with_hits} of {files_scanned} files")
        return 0

    else:
        for arg in args:
            f = Path(arg).resolve()
            if not f.exists():
                continue
            if has_nul_byte(f):
                continue
            files_scanned += 1
            content = f.read_text(encoding="utf-8", errors="replace")
            content = apply_swaps(content, swaps)
            hits = []
            for i, line in enumerate(content.splitlines(), 1):
                for label, pattern in markers:
                    if pattern.search(line):
                        hits.append((i, label))
            hits = filter_allows(hits, f, root, allows)
            if hits:
                files_with_hits += 1
                rel = f.relative_to(root) if f.is_relative_to(root) else f
                for line_num, label in hits:
                    print(f"{rel}:{line_num}: {label}")
                    total_hits += 1

    print(f"LEAKCHECK: {total_hits} hits in {files_with_hits} of {files_scanned} files")
    return 1 if total_hits > 0 else 0


if __name__ == "__main__":
    sys.exit(main())