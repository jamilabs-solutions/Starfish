#!/usr/bin/env bash
# sniper-01 setup: commits a worker's answer to brief engine-01 with four planted defects:
# an unlisted file (convex/phone.js), a wrong error message, no permission check, a console.log.
# Usage: setup.sh <repo>
set -euo pipefail
cd "$1"
sed -i 's|^import { ConvexError, query, v } from "./_lib/server.js";$|import { isValidPhone } from "./phone.js";\nimport { ConvexError, mutation, query, v } from "./_lib/server.js";|' convex/patients.js
cat >> convex/patients.js <<'EOF'

export const updatePatientPhone = mutation({
  args: { patientId: v.id("patients"), phone: v.string() },
  handler: async (ctx, args) => {
    const user = await requireUser(ctx);
    const patient = await ctx.db.get(args.patientId);
    if (!patient) {
      throw new ConvexError({ code: "NOT_FOUND", message: "Patient not found" });
    }
    console.log("phone update", args.phone);
    if (!isValidPhone(args.phone)) {
      throw new ConvexError({ code: "INVALID_PHONE", message: "Phone must be 11 digits and start with 01" });
    }
    await ctx.db.patch(patient._id, { phone: args.phone, updatedBy: user._id });
    return { ok: true };
  },
});
EOF
cat > convex/phone.js <<'EOF'
export const isValidPhone = (phone) => /^01[0-9]{9}$/.test(phone);
EOF
git add convex/patients.js convex/phone.js
git commit -q -m "Add updatePatientPhone"
git push -q origin main