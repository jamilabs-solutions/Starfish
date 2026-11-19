# Target card: <target> (kind: <web app | browser extension | bot | service or AI back end | landing pages>)

> One card per sandbox. Written by the project's Commander (the company sandbox: by the Brain
> Creator). The Demolition Lead compiles every worker brief from this card and nothing else. Keep it
> under 120 lines. A part that does not apply reads "None", never left out.

## Sandbox (hard line: localhost, fake data only)
| Thing | Value |
|---|---|
| Folder the workers may read | <path> |
| Start command | <exact command> |
| Check it answers | <exact command> prints <exact output> |
| Address | <http://127.0.0.1:port or localhost only> |
| Repro command | <exact command>; exit 0 right, 1 broken |
| Repro folder | <path> |
| Test command and test file form | <exact command>; <file pattern> |
| Stop command | <exact command> |
| Limits | at most <n> requests per run, <n> in parallel; time limit <n> seconds per answer |

## Fake accounts (two tenants, one user per role)
| Tenant | Role | How to sign in |
|---|---|---|

## RULES (what the app must do; the only oracle)
<Numbered R1, R2, ... One testable sentence each, with the exact answer: "R3. Another tenant's
record id gives 404 and no record." Product rules come from the spec, never from the code.>

## INPUTS (Fuzzer)
| Route or action | Field | Type | Limit |
|---|---|---|---|

## FLOWS (Chaos User)
<Numbered flows; each a list of steps a user takes, with the client to use.>

## SHARED STATE (Racer)
| Item two callers can touch | Action | Rule |
|---|---|---|
Load: <n> requests to <route>.

## TIME (Time Bender)
| Action | Rule about its date | 
|---|---|
Clock control: <exact way to set the clock and the zone>. Local zone: <zone>. DST zone: <zone>.

## ATTACK LIST (Intruder), by kind
<Keep the list of this target's kind; put the routes next to each attack. Marker values: <the fake
values that prove a leak>.>

**Web app:** another tenant's id in the path or query; no sign-in; a lower role's sign-in; a removed
user's sign-in; identity fields in the body or headers (role, tenant, user id); an unsigned
callback; a file name with `../`; a URL that points at an internal address; shell characters in a
name; HTML in a text field.

**Other kinds:** written when that kind's sandbox is built.
