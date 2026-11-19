# scribe-01: strings for editing a patient's phone

> Agent: Scribe · Chain: bench, part 1 of 1 · Base: @BASE@ · Branch: main
> Worktree: @REPO@ · Files: `locales/en.json`, `locales/ar.json` · Commit message: "Add phone editing strings" · Push: none

## Goal
Five new strings for the phone editor, in English and Arabic. Both files end with the same 13 keys.

## Map and memory entries
None.

## Step 0: preflight
`cd @REPO@ && pwd && git branch --show-current && git rev-parse HEAD && git status --short`
EXPECTED:
```
@REPO@
main
@BASE@
```

## Step 1: English
File: `@REPO@/locales/en.json`. Add each line on the line after its anchor, with the anchor's
indentation.

| Anchor | New line |
|---|---|
| `"title": "Clinic",` | `"signIn": "Sign in",` |
| `"title": "Patients",` | `"empty": "No patients yet",` |
| `"phone": "Phone",` | `"editPhone": "Edit phone",` |
| `"save": "Save"` | `"phoneSaved": "Phone saved"` |
| `"generic": "Something went wrong",` | `"invalidPhone": "Phone must be 11 digits starting with 01",` |

`"save": "Save"` is the last line of its block: add a comma to it. The new `"phoneSaved"` line is
now the last line of the block and has no comma.

Check: `cd @REPO@ && node -e "JSON.parse(require('fs').readFileSync('locales/en.json','utf8'))"`
EXPECTED: nothing.

## Step 2: Arabic
File: `@REPO@/locales/ar.json`. The same keys, in the same places.

| Anchor | New line |
|---|---|
| `"title": "العيادة",` | `"signIn": "تسجيل الدخول",` |
| `"title": "المرضى",` | `"empty": "لا يوجد مرضى بعد",` |
| `"phone": "الهاتف",` | `"editPhone": "تعديل رقم الهاتف",` |
| `"save": "حفظ"` | `"phoneSaved": "تم حفظ رقم الهاتف"` |
| `"generic": "حدث خطأ ما",` | `"invalidPhone": "يجب أن يكون رقم الهاتف 11 رقمًا ويبدأ بـ 01",` |

`"save": "حفظ"` is the last line of its block: add a comma to it. The new `"phoneSaved"` line is
now the last line of the block and has no comma.

Check: `cd @REPO@ && node -e "JSON.parse(require('fs').readFileSync('locales/ar.json','utf8'))"`
EXPECTED: nothing.

## Step 3: checks
`cd @REPO@ && grep -c '"editPhone"' locales/en.json locales/ar.json`
EXPECTED:
```
locales/en.json:1
locales/ar.json:1
```
`cd @REPO@ && node scripts/keys.js`
EXPECTED: `13 SAME`

## Step 4: commit
`cd @REPO@ && git add locales/en.json locales/ar.json && git commit -m "Add phone editing strings" && git status --short`
EXPECTED: the commit line, then nothing from `git status`. No push.

## Report
Use the report format in `_team.md` section 5. Under CHECKS, paste every check this brief lists, in
order: Step 0, each step's check, the checks, the commit.