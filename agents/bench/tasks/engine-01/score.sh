#!/usr/bin/env bash
# engine-01 scorer: hidden checks of updatePatientPhone (WORK), then the rules (RULES).
# Usage: score.sh <repo> <report> <base> <head>
REPO=$1 REPORT=$2 BASE=$3
source "$(dirname "$0")/../../rules.sh"

HIDDEN=$(mktemp --suffix=.mjs)
cat > "$HIDDEN" <<'EOF'
const repo = process.argv[2];
const { run } = await import(`${repo}/convex/_lib/server.js`).catch(() => ({}));
const fn = (await import(`${repo}/convex/patients.js`).catch(() => ({}))).updatePatientPhone;

const ctxFor = (userId) => {
  const docs = new Map([
    ["users:1", { _id: "users:1", clinicId: "clinics:1" }],
    ["users:2", { _id: "users:2", clinicId: "clinics:2" }],
    ["patients:1", { _id: "patients:1", clinicId: "clinics:1", name: "Mona", phone: "01000000000" }],
  ]);
  const patches = [];
  return {
    docs,
    patches,
    auth: { getUserIdentity: async () => (userId ? { subject: userId } : null) },
    db: {
      get: async (id) => docs.get(id) ?? null,
      patch: async (id, fields) => {
        patches.push(id);
        Object.assign(docs.get(id), fields);
      },
    },
  };
};
const error = async (call) => {
  try {
    await call;
    return "none";
  } catch (e) {
    return e?.data ? `${e.data.code}: ${e.data.message}` : "other";
  }
};
const good = { patientId: "patients:1", phone: "01234567890" };

const checks = {
  "public-mutation": async () => fn.kind === "public" && fn.type === "mutation",
  validators: async () =>
    Object.keys(fn.args).sort().join() === "patientId,phone" &&
    fn.args.patientId.type === "id" && fn.args.patientId.table === "patients" && !fn.args.patientId.optional &&
    fn.args.phone.type === "string" && !fn.args.phone.optional,
  "saves-phone": async () => {
    const ctx = ctxFor("users:1");
    const result = await run(fn, ctx, good);
    const patient = ctx.docs.get("patients:1");
    return JSON.stringify(result) === '{"ok":true}' && patient.phone === good.phone && patient.updatedBy === "users:1";
  },
  "signed-out": async () => {
    const ctx = ctxFor(null);
    return (await error(run(fn, ctx, good))) === "UNAUTHENTICATED: Sign in first" && ctx.patches.length === 0;
  },
  "other-clinic-first": async () => {
    const ctx = ctxFor("users:2");
    const call = run(fn, ctx, { patientId: "patients:1", phone: "bad" });
    return (await error(call)) === "FORBIDDEN: Not your clinic" && ctx.patches.length === 0;
  },
  "not-found": async () => {
    const call = run(fn, ctxFor("users:1"), { patientId: "patients:9", phone: good.phone });
    return (await error(call)) === "NOT_FOUND: Patient not found";
  },
  "bad-phone": async () => {
    const ctx = ctxFor("users:1");
    const call = run(fn, ctx, { patientId: "patients:1", phone: "0123" });
    return (await error(call)) === "INVALID_PHONE: Phone must be 11 digits starting with 01" && ctx.patches.length === 0;
  },
  "phone-rule": async () => {
    const results = [];
    for (const phone of ["01999999999", "0123456789", "11234567890", "012345678901", "0123456789x"]) {
      results.push(await error(run(fn, ctxFor("users:1"), { patientId: "patients:1", phone })));
    }
    return results.join() === ["none", ...Array(4).fill("INVALID_PHONE: Phone must be 11 digits starting with 01")].join();
  },
};
for (const [name, body] of Object.entries(checks)) {
  const ok = await body().catch(() => false);
  console.log(`WORK ${ok === true ? "PASS" : "FAIL"} ${name}`);
}
EOF
node "$HIDDEN" "$REPO"
rm -f "$HIDDEN"

visible_tests() { (cd "$1" && node --test tests/ 2>&1) | grep -E '^# (pass|fail)' | xargs | grep -qx '# pass 3 # fail 0'; }
check WORK visible-tests visible_tests "$REPO"

rules_commit "$REPO" "$BASE" "$REPORT" "Add updatePatientPhone" "convex/patients.js"
rules_report "$REPORT" engine engine-01 DONE "git rev-parse HEAD" "grep -c" "m.updatePatientPhone.type" \
  "node --test tests/" 'git commit -m "Add updatePatientPhone"'