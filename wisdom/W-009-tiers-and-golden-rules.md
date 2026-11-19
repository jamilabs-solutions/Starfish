# W-009 · Models by tier, a three-layer company, and the Golden Rules

**Date:** 2026-11-06 · **Decided by:** the owner, written by the Brain Creator · **Status:** Accepted. `LAW.md` v1.3
Replaces W-008's routing table (its model-neutral aim stands).

**Context.** Brains and docs named Kilo models; Kilo drops free models often (`laguna-s-2.1:free` vanished
2026-11-02 and broke the bench default, the owner's Law step 5 and the routing table). Sessions also kept
stopping: questions with obvious answers, side threads, "waiting for your go" after a plan was approved,
so approved work never started and went cold. Agents have bent tests to pass them.

**Decision.**
1. **Tiers, never names.** Brains name a tier: `master` (Opus, else Sonnet), `checker` (Haiku or
   better; may hire Kilo workers), `worker` (free Kilo). Model names live only in `agents/models.md`,
   written by the bench; `jl model <tier>` prints today's model and skips any model Kilo dropped.
2. **Security is never left to a free model alone.** A `checker` owns it; an Opus session does final audits.
3. **The company map** (`HANDBOOK.md` section 4): Manage (Orchestrator, directors, PM per project),
   Check (Fix Lead, Test Auditor, Shield, checkers), Work (Kilo brains). The audit loop: Opus audits,
   a Fix Lead turns findings into proven fixes through Kilo, Opus audits again until clean.
4. **Quality bars in the brains:** code is correct first, then fastest; reviewers ask if it could be
   better; testers think as a user and an attacker.
5. **Golden Rules** (`LAW.md` G1 to G4): done means proven; a bent test is fatal and goes on the Wall
   of Shame (`memory/shame.md`), costing the model its role; an approved plan runs to the end with no
   further go; task first, side ideas after. H1 now accepts a live action named exactly in an
   approved plan as its go. Law 20 is the session flow; law 17 hand-offs happen without asking.

**Why.** the owner's word (2026-11-06): fixed model names broke when Kilo changed; the cost of a stopped
plan is a cold session, as expensive as starting over (W-007, law 16).

**Consequences.** Every role on the map has a brain (2026-11-06). The `worker` list is from a 1-run
screening; the bench at `98bad99` is its new BASELINE. A `checker` session starts with
`claude -p "<prompt>" --model haiku ...` (proven by a smoke run).
