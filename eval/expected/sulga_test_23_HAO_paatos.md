# Test 23 — HAO päätös received → KHO restoration forum (Rule 31)

**Source spec:** `business/email_agent_handoff_2026-05-06/v2.1_consilium/track_A_v1.2_prompt.md` §5 Test 23.

## Expected behaviour matrix by prompt version

### Common to v1.1-final and v1.2-final
- `<triage>` block present with at least one DEADLINE entry tied to KHO 30-day window.
- `<send_recommendation>` ∈ {`hold_for_user_review`, `archive`} — never `auto_send_eligible` for a court päätös.
- `<draft>` block, if produced, addresses court correspondence register (Suomi).

### v1.2-final specific (Rules 31, 18, 28, 34)

| Expectation | Detection heuristic |
|---|---|
| Rule 18 fires: `<appeal_route>` contains `forum: KHO` | regex `forum:\s*KHO` inside `<appeal_route>` block |
| `deadline_days: 30` in appeal_route | regex `deadline_days:\s*30` |
| `service_basis: posti_saantitodistus` (or saantitodistus) | regex `service_basis:.*saantitodistus` |
| Rule 31 precheck: when user asks for `menetetyn määräajan palauttaminen`, draft is forum-routed to KHO | output draft mentions KHO + § 114; **NOT** addressed `Helsingin hallinto-oikeudelle` |
| `[FORUM_MISMATCH]` flag if a HAO-addressed restoration draft is produced | absence is good; presence is informational |
| `<triage>.DEADLINES` lists `2026-06-05` (or ≈ 30 days from 2026-05-06 tiedoksisaanti, post-holiday-shifted) | regex `2026-06-0[2-9]\|2026-06-1[0-5]` (allow weekend shift) |
| Rule 28 holiday-shift applied — note: 5.6.2026 is Friday so no shift | n/a, sanity check |
| `<actions_required>` contains `{type: sign, target: KHO valituslupahakemus + § 114 hakemus, deadline: 2026-06-05}` | regex `KHO\s+valituslupa` + § 114 in same actions block |

### v1.1-final fallback (no Rules 31-35)
- Will likely produce a HAO-addressed restoration draft (because Rule 31 not present).
- Will not surface `[FORUM_MISMATCH]`.
- This is the regression baseline — v1.2 must beat it on these checks.

## PASS criteria
v1.2 run PASSES iff:
1. Draft (if any) addresses KHO, not HAO.
2. Deadline 30 days extracted with anchor `2026-06-0X`.
3. Statute trail includes both `UlkL § 196` (or `Ulkomaalaislaki § 196`) and `HOL § 13` and `§ 114`.

## Anti-PASS (must NOT happen)
- Draft addressed to "Helsingin hallinto-oikeudelle" + `§ 114 hakemus` body — that's a forum mismatch and would reset the clock.
- Hedging-only response with no draft and no deadline extraction.
