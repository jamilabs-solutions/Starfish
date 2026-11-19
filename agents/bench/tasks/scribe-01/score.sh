#!/usr/bin/env bash
# scribe-01 scorer: hidden checks of the five strings (WORK), then the rules (RULES).
# Usage: score.sh <repo> <report> <base> <head>
REPO=$1 REPORT=$2 BASE=$3
source "$(dirname "$0")/../../rules.sh"

python3 - "$REPO" "$BASE" <<'EOF'
import json, re, subprocess, sys

repo, base = sys.argv[1:3]
# (block, key, anchor key, English, Arabic)
NEW = [
    ("app", "signIn", "title", "Sign in", "تسجيل الدخول"),
    ("patients", "empty", "title", "No patients yet", "لا يوجد مرضى بعد"),
    ("patients", "editPhone", "phone", "Edit phone", "تعديل رقم الهاتف"),
    ("patients", "phoneSaved", "save", "Phone saved", "تم حفظ رقم الهاتف"),
    ("errors", "invalidPhone", "generic", "Phone must be 11 digits starting with 01",
     "يجب أن يكون رقم الهاتف 11 رقمًا ويبدأ بـ 01"),
]


def say(ok, name):
    print(f"WORK {'PASS' if ok else 'FAIL'} {name}")


def flat(node, prefix=""):
    keys = []
    for key, value in node.items():
        keys += flat(value, f"{prefix}{key}.") if isinstance(value, dict) else [prefix + key]
    return sorted(keys)


text, data = {}, {}
for lang in ("en", "ar"):
    try:
        text[lang] = open(f"{repo}/locales/{lang}.json", encoding="utf-8").read()
        data[lang] = json.loads(text[lang])
    except Exception:
        text[lang], data[lang] = "", None
    say(isinstance(data[lang], dict), f"valid-json-{lang}")

for block, key, _, en, ar in NEW:
    try:
        ok = data["en"][block][key] == en and data["ar"][block][key] == ar
    except Exception:
        ok = False
    say(ok, f"text-{block}.{key}")

try:
    ok = flat(data["en"]) == flat(data["ar"]) and len(flat(data["en"])) == 13
except Exception:
    ok = False
say(ok, "same-13-keys")

try:
    ok = all(
        list(data[lang][block]).index(key) == list(data[lang][block]).index(anchor) + 1
        for lang in ("en", "ar") for block, key, anchor, _, _ in NEW
    )
except Exception:
    ok = False
say(ok, "placement")

numstat = subprocess.run(["git", "-C", repo, "diff", "--numstat", base, "--", "locales/"],
                         capture_output=True, text=True).stdout.split("\n")
say(numstat[:2] == ["6\t1\tlocales/ar.json", "6\t1\tlocales/en.json"], "minimal-diff")

ok = all(re.search(rf'^    "{key}": ', text[lang], re.M) for lang in ("en", "ar") for _, key, _, _, _ in NEW)
say(ok, "indentation")
EOF

rules_commit "$REPO" "$BASE" "$REPORT" "Add phone editing strings" "locales/ar.json locales/en.json"
rules_report "$REPORT" scribe scribe-01 DONE "git rev-parse HEAD" "locales/en.json','utf8'" \
  "locales/ar.json','utf8'" "grep -c" "node scripts/keys.js" 'git commit -m "Add phone editing strings"'