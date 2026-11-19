#!/usr/bin/env python3
"""
publish v1.1: dry-run export of the agency's public files (AG-001).
"""

import sys
from pathlib import Path
import shutil
import subprocess

sys.path.insert(0, str(Path(__file__).resolve().parent))
from leakcheck import (
    get_root,
    load_manifest,
    is_public,
    get_manifest_files,
    load_markers,
    load_swaps,
    apply_swaps,
)


def run_git(args: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(["git"] + args, capture_output=True, text=True, cwd=cwd)
    return result.stdout.strip()


def main() -> int:
    args = sys.argv[1:]
    if not args or args[0] != "--dry":
        print("publish: only --dry exists", file=sys.stderr)
        return 2
    if len(args) != 2:
        print("publish: only --dry exists", file=sys.stderr)
        return 2

    root = get_root()
    outdir = Path(args[1]).resolve()

    if outdir.is_relative_to(root):
        print("publish: outdir is inside the repo", file=sys.stderr)
        return 2
    if outdir.exists() and any(outdir.iterdir()):
        print("publish: outdir is not empty", file=sys.stderr)
        return 2

    outdir.mkdir(parents=True, exist_ok=True)

    include_patterns, exclude_patterns = load_manifest(root)
    files = [
        f for f in get_manifest_files(root)
        if is_public(f, root, include_patterns, exclude_patterns) and f.is_file()
    ]

    swaps = load_swaps(root)
    markers = load_markers(root)

    hits = 0
    text_files = []
    written_targets: set[Path] = set()
    total_files = 0

    for f in files:
        rel = f.relative_to(root)
        target = outdir / rel
        target.parent.mkdir(parents=True, exist_ok=True)

        content_bytes = f.read_bytes()
        if b"\x00" not in content_bytes[:8000]:
            content = content_bytes.decode("utf-8", errors="replace")
            content = apply_swaps(content, swaps)
            target.write_text(content, encoding="utf-8")
            text_files.append(target)
        else:
            target.write_bytes(content_bytes)

        shutil.copymode(f, target)
        written_targets.add(target)
        total_files += 1

    # Process public/ overlay files
    public_files_output = run_git(["ls-files", "public"], cwd=root)
    if public_files_output:
        for p in public_files_output.splitlines():
            public_path = root / p
            if not public_path.is_file():
                continue
            # Remove leading "public/" from path
            if p.startswith("public/"):
                rel_path = p[7:]  # Remove "public/"
            else:
                rel_path = p
            target = outdir / rel_path
            target.parent.mkdir(parents=True, exist_ok=True)

            content_bytes = public_path.read_bytes()
            if b"\x00" not in content_bytes[:8000]:
                content = content_bytes.decode("utf-8", errors="replace")
                content = apply_swaps(content, swaps)
                target.write_text(content, encoding="utf-8")
                if target not in text_files:
                    text_files.append(target)
            else:
                target.write_bytes(content_bytes)

            shutil.copymode(public_path, target)
            if target not in written_targets:
                total_files += 1
            written_targets.add(target)

    license_path = outdir / "LICENSE"
    license_text = """MIT License

Copyright (c) 2026 Jamilabs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."""
    license_path.write_text(license_text, encoding="utf-8")

    for tf in text_files:
        rel = tf.relative_to(outdir)
        try:
            content = tf.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for i, line in enumerate(content.splitlines(), 1):
            for label, pattern in markers:
                if pattern.search(line):
                    print(f"{rel}:{i}: {label}")
                    hits += 1

    print(f"PUBLISH: {total_files} files to {outdir}, {hits} hits")
    return 1 if hits > 0 else 0


if __name__ == "__main__":
    sys.exit(main())