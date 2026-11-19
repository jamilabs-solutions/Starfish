#!/usr/bin/env python3
"""keep v1.0.1: last-good store for company files (K-001)."""

import os
import sys
import json
import hashlib
import fnmatch
import shutil
import tempfile
import glob
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

ROOT = Path(os.environ.get("JL_KEEP_ROOT", Path(__file__).parent.parent)).resolve()
STATE = Path(os.environ.get("JL_KEEP_STATE", Path.home() / ".local/state/jl-keep")).resolve()
INDEX_FILE = STATE / "index.json"
STORE_DIR = STATE / "store"
VERSIONS_DIR = STATE / "versions"
QUARANTINE_DIR = STATE / "quarantine"
LOG_FILE = STATE / "log.txt"

DEFAULT_PATTERNS = [
    "LAW.md", "AGENTS.md", "CLAUDE.md", "HANDBOOK.md", "MAP.md", "PLAYBOOK.md",
    "HANDOFF.md", "README.md", "jl", "agents/*.md", "agents/*/*.md",
    "agents/memory/*", "templates/*", "wisdom/*", "memory/*", "plans/*.md",
    "plans/*/*.md", "tools/*.py", "tools/*.sh", "*/CLAUDE.md",
]

SKIP_DIRS = {".git", "__pycache__", "jl-runs", "node_modules"}


def ensure_state_dirs() -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    STORE_DIR.mkdir(parents=True, exist_ok=True)
    VERSIONS_DIR.mkdir(parents=True, exist_ok=True)
    QUARANTINE_DIR.mkdir(parents=True, exist_ok=True)


def load_index() -> Dict:
    if INDEX_FILE.exists():
        with INDEX_FILE.open("r") as f:
            try:
                return json.load(f)
            except ValueError:
                print("keep: index.json was corrupt, rebuilt", file=sys.stderr)
                return {}
    return {}


def save_index(index: Dict) -> None:
    tmp = INDEX_FILE.with_suffix(".json.tmp")
    with tmp.open("w") as f:
        json.dump(index, f, indent=2)
    os.replace(tmp, INDEX_FILE)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def words_count(data: bytes) -> int:
    return len(data.decode("utf-8", errors="replace").split())


def load_patterns() -> List[str]:
    paths_file = os.environ.get("JL_KEEP_PATHS")
    if paths_file:
        with open(paths_file, "r") as f:
            return [line.strip() for line in f if line.strip() and not line.startswith("#")]
    patterns_file = ROOT / "tools" / "keep_paths.txt"
    if patterns_file.exists():
        with patterns_file.open("r") as f:
            return [line.strip() for line in f if line.strip() and not line.startswith("#")]
    return DEFAULT_PATTERNS


def is_protected(rel_path: str, patterns: List[str]) -> bool:
    for skip in SKIP_DIRS:
        if f"/{skip}/" in f"/{rel_path}/" or rel_path.startswith(f"{skip}/"):
            return False
    for pattern in patterns:
        if fnmatch.fnmatch(rel_path, pattern):
            return True
    return False


def walk_protected_files(patterns: List[str]) -> List[Path]:
    files = []
    seen = set()
    for pattern in patterns:
        for p in sorted(glob.glob(pattern, root_dir=str(ROOT))):
            full = ROOT / p
            if full.is_file() and is_protected(p, patterns):
                if p not in seen:
                    seen.add(p)
                    files.append(full)
    return files


def log_restore(message: str) -> None:
    with LOG_FILE.open("a") as f:
        f.write(message + "\n")


def quarantine_path(rel_path: str) -> Path:
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    safe = rel_path.replace("/", "__")
    return QUARANTINE_DIR / f"{ts}-{safe}"


def versions_path(rel_path: str) -> Path:
    safe = rel_path.replace("/", "__")
    return VERSIONS_DIR / f"{safe}.txt"


def update_versions(rel_path: str, sha: str) -> None:
    vpath = versions_path(rel_path)
    lines = []
    if vpath.exists():
        with vpath.open("r") as f:
            lines = [line.strip() for line in f if line.strip()]
    lines.append(sha)
    if len(lines) > 5:
        lines = lines[-5:]
    with vpath.open("w") as f:
        f.write("\n".join(lines) + "\n")


def cmd_check() -> int:
    ensure_state_dirs()
    patterns = load_patterns()
    index = load_index()
    restored_any = False

    protected = walk_protected_files(patterns)
    for fpath in protected:
        try:
            rel = str(fpath.relative_to(ROOT))
        except ValueError:
            continue
        stat = fpath.stat()
        entry = index.get(rel)
        if entry and entry.get("mtime") == stat.st_mtime and entry.get("size") == stat.st_size:
            continue
        data = fpath.read_bytes()
        w = words_count(data)
        sha = sha256_bytes(data)
        if entry:
            L = entry
            L_words = L.get("words", 0)
            L_size = L.get("size", 0)
            bad = (L_size > 0 and stat.st_size == 0) or (L_words >= 20 and w < L_words / 2)
        else:
            bad = False
        if not bad:
            if sha != entry.get("sha") if entry else True:
                (STORE_DIR / sha).write_bytes(data)
                update_versions(rel, sha)
                index[rel] = {"mtime": stat.st_mtime, "size": stat.st_size, "words": w, "sha": sha}
            continue
        qpath = quarantine_path(rel)
        qpath.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(fpath, qpath)
        good_sha = entry["sha"]
        good_data = (STORE_DIR / good_sha).read_bytes()
        tmp = fpath.with_suffix(fpath.suffix + ".keep-tmp")
        tmp.write_bytes(good_data)
        os.replace(tmp, fpath)
        good_stat = fpath.stat()
        index[rel] = {"mtime": good_stat.st_mtime, "size": good_stat.st_size, "words": words_count(good_data), "sha": good_sha}
        msg = f"KEEP: restored {rel} ({w} words, last good {entry['words']} words). Cut copy: {qpath}. A cut this big needs the owner: he runs keep.py accept {rel} in a terminal."
        print(msg, file=sys.stderr)
        log_restore(msg)
        restored_any = True

    for rel, entry in list(index.items()):
        fpath = ROOT / rel
        if not fpath.exists():
            good_sha = entry["sha"]
            good_data = (STORE_DIR / good_sha).read_bytes()
            fpath.parent.mkdir(parents=True, exist_ok=True)
            tmp = fpath.with_suffix(fpath.suffix + ".keep-tmp")
            tmp.write_bytes(good_data)
            os.replace(tmp, fpath)
            good_stat = fpath.stat()
            index[rel] = {"mtime": good_stat.st_mtime, "size": good_stat.st_size, "words": words_count(good_data), "sha": good_sha}
            msg = f"KEEP: restored {rel} (0 words, last good {entry['words']} words). Cut copy: {quarantine_path(rel)}. A cut this big needs the owner: he runs keep.py accept {rel} in a terminal."
            print(msg, file=sys.stderr)
            log_restore(msg)
            restored_any = True

    save_index(index)
    return 2 if restored_any else 0


def cmd_hook() -> int:
    sys.stdin.read()
    return cmd_check()


def cmd_status() -> int:
    ensure_state_dirs()
    index = load_index()
    restores = 0
    if LOG_FILE.exists():
        with LOG_FILE.open("r") as f:
            restores = sum(1 for _ in f)
    print(f"{len(index)} files kept, {restores} restores")
    return 0


def cmd_accept(path: str) -> int:
    if not sys.stdin.isatty():
        print("keep: accept needs a terminal (the owner only)", file=sys.stderr)
        return 1
    ensure_state_dirs()
    index = load_index()
    fpath = ROOT / path
    try:
        rel = str(fpath.relative_to(ROOT))
    except ValueError:
        rel = path
    ans = input(f"Accept {rel} as it is now? type yes: ")
    if ans.strip() == "yes":
        if fpath.exists():
            data = fpath.read_bytes()
            sha = sha256_bytes(data)
            (STORE_DIR / sha).write_bytes(data)
            update_versions(rel, sha)
            stat = fpath.stat()
            index[rel] = {"mtime": stat.st_mtime, "size": stat.st_size, "words": words_count(data), "sha": sha}
        else:
            index.pop(rel, None)
        save_index(index)
        log_restore(f"KEEP: accepted {rel}")
        return 0
    return 1


def cmd_precommit() -> int:
    import subprocess
    try:
        repo_root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    except subprocess.CalledProcessError:
        return 0
    try:
        diff = subprocess.check_output(["git", "diff", "--cached", "--name-only", "--diff-filter=MD"], text=True, cwd=repo_root).strip().splitlines()
    except subprocess.CalledProcessError:
        return 0
    patterns = load_patterns()
    blocked = False
    for path in diff:
        if not path:
            continue
        rel = path
        if not is_protected(rel, patterns):
            continue
        try:
            new_data = subprocess.check_output(["git", "show", f":{path}"], cwd=repo_root)
        except subprocess.CalledProcessError:
            new_data = b""
        try:
            old_data = subprocess.check_output(["git", "show", f"HEAD:{path}"], cwd=repo_root)
        except subprocess.CalledProcessError:
            old_data = b""
        new_w = words_count(new_data)
        old_w = words_count(old_data)
        if (len(old_data) > 0 and len(new_data) == 0) or (old_w >= 20 and new_w < old_w / 2):
            print(f"KEEP: commit blocked: {path} goes from {old_w} to {new_w} words.", file=sys.stderr)
            blocked = True
    return 1 if blocked else 0


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: keep.py check | hook | status | accept <path> | precommit", file=sys.stderr)
        return 1
    cmd = sys.argv[1]
    if cmd == "check":
        return cmd_check()
    elif cmd == "hook":
        return cmd_hook()
    elif cmd == "status":
        return cmd_status()
    elif cmd == "accept":
        if len(sys.argv) < 3:
            print("Usage: keep.py accept <path>", file=sys.stderr)
            return 1
        return cmd_accept(sys.argv[2])
    elif cmd == "precommit":
        return cmd_precommit()
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())