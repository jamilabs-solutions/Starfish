#!/usr/bin/env python3
"""jl handoff: one HANDOFF.md per project, one section per seat, read-only archive (templates/handoff.md).
read <seat> | write <seat> <draft> --owner ID [--take] | highlights <file> | import <seat> <old-file>
"""
import fcntl, os, re, subprocess, sys, time

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd()
HF = os.path.join(ROOT, "HANDOFF.md")
ARCH = os.path.join(ROOT, "handoffs", "archive")
MAX_WORDS, MAX_HL = 400, 15
SECRET = re.compile(r"(sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{35}"
                    r"|gsk_[A-Za-z0-9]{20,}|xox[bap]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY)")
SEAT_RE = re.compile(r"^[a-z0-9-]+$")


def die(msg):
    print("HANDOFF FAIL: " + msg)
    sys.exit(1)


def load():
    if not os.path.exists(HF):
        return "# HANDOFF\n\n## Highlights\n- (none yet)\n", {}
    head, seats, cur = [], {}, None
    for line in open(HF, encoding="utf-8").read().splitlines(keepends=True):
        m = re.match(r"^## Seat: ([a-z0-9-]+)\s*$", line)
        if m:
            cur = m.group(1)
            seats[cur] = ""
        elif cur:
            seats[cur] += line
        else:
            head.append(line)
    return "".join(head), seats


def save(head, seats):
    body = head.rstrip("\n") + "\n"
    for s in sorted(seats):
        body += "\n## Seat: " + s + "\n" + seats[s].strip("\n") + "\n"
    tmp = HF + ".tmp"
    open(tmp, "w", encoding="utf-8").write(body)
    os.replace(tmp, HF)


def tamper():
    r = subprocess.run(["git", "-C", ROOT, "status", "--porcelain", "--", "handoffs/archive"],
                       capture_output=True, text=True).stdout
    bad = [l for l in r.splitlines() if not l.startswith("??")]
    if bad:
        die("ARCHIVE TAMPERED: " + "; ".join(bad))


def paths(text):
    miss = []
    for p in re.findall(r"`([^`\s<>*]+)`", text):
        p = re.sub(r":\d+(-\d+)?$", "", p)
        if "/" in p or re.search(r"\.(md|py|sh|tsv|txt|json)$", p):
            if not os.path.exists(os.path.join(ROOT, p)):
                miss.append(p)
    return miss


def archive(seat, text, src_name=None):
    os.makedirs(ARCH, exist_ok=True)
    name = time.strftime("%Y-%m-%d-%H%M") + "-" + seat + ("-" + src_name if src_name else "") + ".md"
    dst = os.path.join(ARCH, name)
    if os.path.exists(dst):
        die("archive exists: " + dst)
    open(dst, "w", encoding="utf-8").write(text)
    os.chmod(dst, 0o444)
    return os.path.relpath(dst, ROOT)


def lock():
    f = open(HF + ".lock", "w")
    try:
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        die("another session is writing HANDOFF.md; retry in a minute")
    return f


def main(a):
    if len(a) < 2 or a[0] not in ("read", "write", "highlights", "import"):
        die("usage: jl handoff read <seat> | write <seat> <draft> --owner ID [--take] | highlights <file> | import <seat> <old-file>")
    tamper()
    head, seats = load()
    if a[0] == "read":
        seat = a[1]
        print(head.rstrip("\n"))
        print("\n## Seat: " + seat + "\n" + seats.get(seat, "(no section yet)\n").strip("\n"))
        miss = paths(head + seats.get(seat, ""))
        print("PATHS: " + ("all found" if not miss else "MISSING " + " ".join(miss)))
        return
    lk = lock()
    if a[0] == "highlights":
        text = open(a[1], encoding="utf-8").read().strip("\n")
        n = len([l for l in text.splitlines() if l.strip()])
        if n > MAX_HL:
            die(f"highlights {n} lines > {MAX_HL}: replace an old line, do not add")
        if SECRET.search(text):
            die("secret pattern found (H2)")
        title = head.splitlines()[0]
        save(title + "\n\n## Highlights\n" + text + "\n", seats)
        print(f"HANDOFF OK: highlights {n} lines")
    elif a[0] == "import":
        seat, src = a[1], a[2]
        if not SEAT_RE.match(seat):
            die("seat must be a-z, 0-9, -")
        data = open(src, encoding="utf-8").read()
        dst = archive(seat, data, re.sub(r"[^a-zA-Z0-9-]", "-", os.path.basename(src)[:-3]))
        if open(os.path.join(ROOT, dst), encoding="utf-8").read() != data:
            die("archive copy differs; original kept")
        tracked = subprocess.run(["git", "-C", ROOT, "ls-files", "--error-unmatch", src], capture_output=True).returncode == 0
        subprocess.run(["git", "-C", ROOT, "rm", "-q", "-f", src]) if tracked else os.remove(src)
        print(f"HANDOFF OK: {src} -> {dst} (read-only)")
    elif a[0] == "write":
        seat, draft = a[1], a[2]
        owner = a[a.index("--owner") + 1] if "--owner" in a else die("--owner ID is required")
        if not SEAT_RE.match(seat):
            die("seat must be a-z, 0-9, -")
        text = open(draft, encoding="utf-8").read().strip("\n")
        words = len(text.split())
        if words > MAX_WORDS:
            die(f"{words} words > {MAX_WORDS}: cut, point to files instead")
        if SECRET.search(text):
            die("secret pattern found (H2)")
        miss = paths(text)
        if miss:
            die("missing paths: " + " ".join(miss))
        old = seats.get(seat, "")
        m = re.search(r"owner: (\S+)", old)
        if m and m.group(1) != owner and "--take" not in a:
            die(f"seat {seat} is owned by {m.group(1)}; add --take only if that session has ended")
        prev = archive(seat, "## Seat: " + seat + "\n" + old) if old.strip() else "none"
        seats[seat] = f"> owner: {owner} · updated: {time.strftime('%Y-%m-%d %H:%M')} · previous: `{prev}`\n\n" + text + "\n"
        save(head, seats)
        print(f"HANDOFF OK: seat {seat}, {words} words, previous {prev}")
    lk.close()


if __name__ == "__main__":
    main(sys.argv[1:])
