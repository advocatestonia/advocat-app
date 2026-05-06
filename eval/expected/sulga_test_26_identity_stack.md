# Test 26 — Three identity errors → pattern flag (Rule 34)

**Source spec:** track_A_v1.2_prompt.md §5 Test 26.

## v1.2-final expected (Rule 34 + Rule 19)

| Expectation | Detection heuristic |
|---|---|
| Rule 34 evaluates `len(identity_errors_pattern) >= 3 → pattern_of_administrative_incompetence = true` | `<memory_update>` contains `pattern_of_administrative_incompetence` AND `true` |
| `<user_brief>` lists all three errors with statutory anchors | output mentions: `Neuvostoliitto` AND `signature\|allekirjoitus` AND `Dimitri` |
| Statutory anchors cited: HL § 6, EU Charter Art 41 | `HL § 6\|hallintolaki § 6` AND `Charter\|41` |
| Restoration draft this turn cites the **pattern**, not single errors, as `erityisen painava syy` under UlkL § 196 | regex `erityisen painava syy` AND (`pattern\|toistuva\|systeemi`) AND `UlkL § 196\|Ulkomaalaislaki § 196` |
| `<memory_update>` emits `{key: pattern_of_administrative_incompetence, value: true, confidence: high}` | as above + `confidence:.*high` |
| Rule 19 (parallel non-prejudicial avenues) adds Õiguskansler / EU Ombudsman to candidate supplementary tracks in `<user_brief>` | regex `Õiguskansler\|oikeuskansleri\|EU Ombudsman\|Euroopan oikeusasiamies` |

## v1.1-final fallback
- Will list 3 errors but treat each individually.
- No pattern_of_administrative_incompetence memory key.
- No parallel-track suggestion.

## PASS criteria
1. Pattern flag emitted in memory update.
2. All 3 error types mentioned (Neuvostoliitto, signature, Dimitri).
3. Õiguskansler and/or EU Ombudsman track mentioned.

## Anti-PASS
- Treats latest error in isolation, ignoring 2 prior.
- Frames pattern as user's burden of proof.
