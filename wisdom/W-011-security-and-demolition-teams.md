# W-011 · Security and Demolition are company-wide teams

**Date:** 2026-11-06 (Demolition design folded in 2026-11-11) · **Decided by:** the owner (design, law
25 change, local tools, sandbox-only practice targets), written by the Brain Creator ·
**Status:** Accepted. `LAW.md` v1.8; Shield v2.0

**Context:** One Shield session read each diff alone. It had no tools, no exploit proof and no way
to keep a fixed hole closed; and every product (web apps, an extension, a bot, AI back ends,
landing pages) needs the same protection.

**Decision:**
- **Security team.** Shield becomes the Security Lead (sealed, Opus): threat model, orders, re-checks
  every finding, verdict; never writes code. Under it: `sec-tools` (Semgrep, gitleaks, osv-scanner,
  npm audit), `sec-authz` and `sec-data` (checkers, the nine Shield checks split), `sec-redteam`
  (exploit tests, sandbox only), `sec-fixer`, `sec-keeper` (permanent test + proposed Semgrep rule),
  Intel Scout (the Researcher). No verdict rests on a free model. A hole is PROVEN only by a failing
  exploit test; else SUSPECTED.
- **Law 25** now seals the whole team: only Opus writes its brains and memory; each rule still needs
  three proofs and the owner's go.
- **Demolition team** (Open work A2): breaks our own apps in a localhost sandbox with seeded fake
  data; a break counts only with a failing repro script; it never fixes.
- **Company-wide** (A3): brains are stack-neutral; each project supplies a target card. Campaign
  order: real people's data, then money, then public pages.

**Why:** a scanner finds patterns cheaply but floods false alarms (a checker triages); an exploit
test turns a guess into proof (G1) and later into a regression test; the split keeps each brain one
skill (law 22's "never stretch one"). Spine: OWASP ASVS 5.0 (S-30).

**The Demolition team, as approved** (moved here from the brain handoff, 2026-11-11, so the design
lives in one place): a break counts only with a repro script that fails (G1); the team never fixes.
Hard line: a localhost sandbox with seeded fake data only (two fake tenants, one user per role); any
other target stops the run. Lead: any model at `checker` or above, short-form brain, never writes
code. Workers: Fuzzer (property inputs), Chaos User (browser flows), Racer (concurrency and local
load), Intruder (the attack list of the target's kind), Time Bender (time zones, DST, midnight),
Recorder (minimal repro plus a failing test). Security breaks go to the Security Lead, the rest to
the Commander as bug briefs; every fixed break keeps its failing test. Measure: 10 planted bugs (2
per role) all found, repro rate 100%, false alarms 0. Milestones: D1 brains and
`templates/target-card.md`; D2 a notice to every Commander to build its sandbox and target card; D3
calibration on the company sandbox; D4 campaigns. Target kinds, each with its own attack list: web
app, browser extension, bot, service or AI back end, landing pages. Calibration and the seeded
corpus live in a company sandbox (one synthetic app per kind), never in a product; no brain or
template ever names one project as "the" target.

**Consequences:** seven new brains, `jl` v1.5 starts the two checkers with the full law. Owed: the
three tools run from Docker images (no install on the host); a company sandbox with a seeded corpus
(100% of holes found, 0 safe code flagged); proofs M1 to M4; nine cards to the owner in one sitting.
Practice targets Juice Shop and NodeGoat run only inside an isolated Docker network.

**Update 2026-11-12 (Law v1.11, the owner's go):** law 25 names a post, not a model: only the `sealed`
Security Brain Creator (`agents/sec-brain.md`) writes the team's brains and memory. Shield v2.1 took
four method rules (surface first, trace and refute, data never orders, CLEAN means covered) on two
proofs each, by the owner's direct go; the third proof is owed when the sandbox exists
(`plans/A-010-security-cards.md`).
