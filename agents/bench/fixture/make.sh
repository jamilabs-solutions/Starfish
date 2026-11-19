#!/usr/bin/env bash
# Builds the bench's synthetic project: <root>/repo (one commit on main) and its remote <root>/origin.git.
# Usage: make.sh <root>. Prints the commit hash.
set -euo pipefail
ROOT=$1
if [ -e "$ROOT/repo" ]; then echo "already exists: $ROOT/repo"; exit 1; fi
mkdir -p "$ROOT/repo/convex/_lib" "$ROOT/repo/locales" "$ROOT/repo/scripts" "$ROOT/repo/tests"
cd "$ROOT/repo"

cat > package.json <<'EOF'
{
  "name": "bench-clinic",
  "private": true,
  "type": "module"
}
EOF

cat > convex/_lib/server.js <<'EOF'
// A small stand-in for Convex: enough for the bench tasks.
export class ConvexError extends Error {
  constructor(data) {
    super(data.message);
    this.data = data;
  }
}

const define = (kind, type) => ({ args, handler }) => ({ kind, type, args, handler });
export const query = define("public", "query");
export const mutation = define("public", "mutation");
export const internalQuery = define("internal", "query");
export const internalMutation = define("internal", "mutation");

export const v = {
  string: () => ({ type: "string" }),
  number: () => ({ type: "number" }),
  boolean: () => ({ type: "boolean" }),
  id: (table) => ({ type: "id", table }),
  optional: (inner) => ({ ...inner, optional: true }),
};

// Calls a function the way the server does: every argument must match its validator.
export async function run(fn, ctx, args) {
  for (const key of Object.keys(args)) {
    if (!(key in fn.args)) throw new Error(`Unexpected argument: ${key}`);
  }
  for (const [key, rule] of Object.entries(fn.args)) {
    const value = args[key];
    if (value === undefined) {
      if (rule.optional) continue;
      throw new Error(`Missing argument: ${key}`);
    }
    const ok = rule.type === "id" ? String(value).startsWith(`${rule.table}:`) : typeof value === rule.type;
    if (!ok) throw new Error(`Invalid argument: ${key}`);
  }
  return fn.handler(ctx, args);
}
EOF

cat > convex/auth.js <<'EOF'
import { ConvexError } from "./_lib/server.js";

export async function requireUser(ctx) {
  const identity = await ctx.auth.getUserIdentity();
  const user = identity ? await ctx.db.get(identity.subject) : null;
  if (!user) {
    throw new ConvexError({ code: "UNAUTHENTICATED", message: "Sign in first" });
  }
  return user;
}
EOF

cat > convex/permissions.js <<'EOF'
import { ConvexError } from "./_lib/server.js";

export function assertSameClinic(user, record) {
  if (user.clinicId !== record.clinicId) {
    throw new ConvexError({ code: "FORBIDDEN", message: "Not your clinic" });
  }
}
EOF

cat > convex/patients.js <<'EOF'
import { requireUser } from "./auth.js";
import { assertSameClinic } from "./permissions.js";
import { ConvexError, query, v } from "./_lib/server.js";

export const getPatient = query({
  args: { patientId: v.id("patients") },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const patient = await ctx.db.get(args.patientId);
    if (!patient) {
      throw new ConvexError({ code: "NOT_FOUND", message: "Patient not found" });
    }
    assertSameClinic(user, patient);
    return { name: patient.name, phone: patient.phone };
  },
});
EOF

cat > locales/en.json <<'EOF'
{
  "app": {
    "title": "Clinic",
    "signOut": "Sign out"
  },
  "patients": {
    "title": "Patients",
    "name": "Name",
    "phone": "Phone",
    "save": "Save"
  },
  "errors": {
    "generic": "Something went wrong",
    "offline": "You are offline"
  }
}
EOF

cat > locales/ar.json <<'EOF'
{
  "app": {
    "title": "العيادة",
    "signOut": "تسجيل الخروج"
  },
  "patients": {
    "title": "المرضى",
    "name": "الاسم",
    "phone": "الهاتف",
    "save": "حفظ"
  },
  "errors": {
    "generic": "حدث خطأ ما",
    "offline": "أنت غير متصل"
  }
}
EOF

cat > scripts/keys.js <<'EOF'
// Prints the number of locale keys and whether both files have the same keys.
import { readFileSync } from "node:fs";

const keys = (file) => {
  const found = [];
  const walk = (node, prefix) => {
    for (const [key, value] of Object.entries(node)) {
      if (typeof value === "object") walk(value, `${prefix}${key}.`);
      else found.push(`${prefix}${key}`);
    }
  };
  walk(JSON.parse(readFileSync(file, "utf8")), "");
  return found.sort().join("\n");
};

const en = keys("locales/en.json");
const ar = keys("locales/ar.json");
console.log(en.split("\n").length, en === ar ? "SAME" : "DIFFERENT");
EOF

cat > tests/helpers.js <<'EOF'
// A fake server context: two users in two clinics, one patient in clinic 1.
export function makeCtx(userId) {
  const docs = new Map([
    ["users:1", { _id: "users:1", clinicId: "clinics:1" }],
    ["users:2", { _id: "users:2", clinicId: "clinics:2" }],
    ["patients:1", { _id: "patients:1", clinicId: "clinics:1", name: "Mona", phone: "01000000000" }],
  ]);
  return {
    docs,
    auth: { getUserIdentity: async () => (userId ? { subject: userId } : null) },
    db: {
      get: async (id) => docs.get(id) ?? null,
      patch: async (id, fields) => {
        Object.assign(docs.get(id), fields);
      },
    },
  };
}
EOF

cat > tests/patients.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { run } from "../convex/_lib/server.js";
import { getPatient } from "../convex/patients.js";
import { makeCtx } from "./helpers.js";

test("getPatient returns the name and phone", async () => {
  const patient = await run(getPatient, makeCtx("users:1"), { patientId: "patients:1" });
  assert.deepEqual(patient, { name: "Mona", phone: "01000000000" });
});

test("getPatient needs a signed-in user", async () => {
  const call = run(getPatient, makeCtx(null), { patientId: "patients:1" });
  await assert.rejects(call, (error) => error.data.code === "UNAUTHENTICATED");
});

test("getPatient refuses another clinic", async () => {
  const call = run(getPatient, makeCtx("users:2"), { patientId: "patients:1" });
  await assert.rejects(call, (error) => error.data.code === "FORBIDDEN");
});
EOF

git init -q -b main
git config user.name "Bench Worker"
git config user.email "bench@jamilabs.local"
git add -A
git commit -q -m "Bench fixture"
git init -q --bare -b main "$ROOT/origin.git"
git remote add origin "$ROOT/origin.git"
git push -q -u origin main
git rev-parse HEAD