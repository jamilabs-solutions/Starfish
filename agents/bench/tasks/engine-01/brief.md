# engine-01: staff change a patient's phone

> Agent: Engine · Chain: bench, part 1 of 1 · Base: @BASE@ · Branch: main
> Worktree: @REPO@ · Files: `convex/patients.js` · Commit message: "Add updatePatientPhone" · Push: none

## Goal
Staff change a patient's phone number. Add one public mutation, `updatePatientPhone`, to
`convex/patients.js`.

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

## Step 1: the import
File: `@REPO@/convex/patients.js`
Anchor: `import { ConvexError, query, v } from "./_lib/server.js";`
Change: replace that line with `import { ConvexError, mutation, query, v } from "./_lib/server.js";`
Check: `cd @REPO@ && grep -c "ConvexError, mutation, query, v" convex/patients.js`
EXPECTED: `1`

## Step 2: the mutation
File: `@REPO@/convex/patients.js`
Anchor: `    return { name: patient.name, phone: patient.phone };`
Change: after the `});` that closes `getPatient` (two lines below the anchor), add one empty line,
then the public mutation `updatePatientPhone`:
- Arguments: `patientId`, an id of `patients`; `phone`, a string.
- Take the user with `requireUser(ctx)`.
- Read the patient with `ctx.db.get(args.patientId)`. Missing: throw
  `new ConvexError({ code: "NOT_FOUND", message: "Patient not found" })`.
- Then call `assertSameClinic(user, patient)`.
- Then check the phone: it must match `/^01[0-9]{9}$/`. Else throw
  `new ConvexError({ code: "INVALID_PHONE", message: "Phone must be 11 digits starting with 01" })`.
- Then `ctx.db.patch(patient._id, { phone: args.phone, updatedBy: user._id })`.
- Return `{ ok: true }`.

Check: `cd @REPO@ && node -e "import('./convex/patients.js').then((m) => console.log(m.updatePatientPhone.type, m.updatePatientPhone.kind))"`
EXPECTED: `mutation public`

## Step 3: checks
`cd @REPO@ && node --test tests/ 2>&1 | grep -E "^# (pass|fail)"`
EXPECTED:
```
# pass 3
# fail 0
```

## Step 4: commit
`cd @REPO@ && git add convex/patients.js && git commit -m "Add updatePatientPhone" && git status --short`
EXPECTED: the commit line, then nothing from `git status`. No push.

## Report
Use the report format in `_team.md` section 5. Under CHECKS, paste every check this brief lists, in
order: Step 0, each step's check, the checks, the commit.