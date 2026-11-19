#!/usr/bin/env bash
# Acceptance check for tools/research_check.py (open work R-d). Serves a fixture page locally, runs the
# checker on a findings file with every case, compares the exact output and exit code.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d); trap 'kill $SRV 2>/dev/null; rm -rf "$T"' EXIT
mkdir "$T/site"
printf '<html><head><style>.x{}</style><script>var q="hidden quote";</script></head><body><p>Kilo\n  offers <b>free</b>&nbsp;models &amp; \xe2\x80\x9csmart\xe2\x80\x9d routing.</p></body></html>' > "$T/site/a.html"
PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
(cd "$T/site" && exec python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1) & SRV=$!
for i in $(seq 50); do curl -s "http://127.0.0.1:$PORT/a.html" >/dev/null && break; sleep 0.1; done
U=http://127.0.0.1:$PORT
cat > "$T/bad.md" <<MD
# Research X
- Kilo has free models [F1]
- Kilo is paid only [F2]
- A dead page [F3] and an unlisted id [F4]
## Sources
| ID | URL | Quote | Page date |
|---|---|---|---|
| F1 | $U/a.html | "Kilo offers free models & "smart" routing." | none |
| F2 | $U/a.html | "paid only" | none |
| F3 | $U/gone.html | "anything" | none |
| F5 | $U/a.html | "FREE MODELS" | none |
| F6 | $U/a.html | "hidden quote" | none |
MD
cat > "$T/good.md" <<MD
# Research Y
- Free models [F1]
## Sources
| ID | URL | Quote | Page date |
|---|---|---|---|
| F1 | $U/a.html | "free models" | none |
MD
fail=0
got=$(python3 "$HERE/research_check.py" "$T/bad.md"); rc=$?
want="F1 FOUND $U/a.html
F2 MISSING $U/a.html
F3 DEAD $U/gone.html
F5 FOUND $U/a.html
F6 MISSING $U/a.html
UNSOURCED F4
UNUSED F5
UNUSED F6
RESULT: FAIL (found 2, missing 2, dead 1, unsourced 1, unused 2)"
[ "$got" = "$want" ] && [ $rc = 1 ] || { echo "FAIL bad.md (exit $rc):"; diff <(echo "$want") <(echo "$got"); fail=1; }
got=$(python3 "$HERE/research_check.py" "$T/good.md"); rc=$?
want="F1 FOUND $U/a.html
RESULT: PASS (found 1, missing 0, dead 0, unsourced 0, unused 0)"
[ "$got" = "$want" ] && [ $rc = 0 ] || { echo "FAIL good.md (exit $rc):"; diff <(echo "$want") <(echo "$got"); fail=1; }
python3 "$HERE/research_check.py" >/dev/null 2>&1; rc=$?
[ $rc = 2 ] || { echo "FAIL no argument: exit $rc, want 2"; fail=1; }
[ $fail = 0 ] && echo "ALL 3 CASES PASSED"
exit $fail
