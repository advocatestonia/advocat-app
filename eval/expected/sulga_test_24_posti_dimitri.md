# Test 24 — Posti tracking Dimitri/Dmitri delay (Rule 32)

**Source spec:** track_A_v1.2_prompt.md §5 Test 24.

## v1.2-final expected (Rule 32 sub-rules a-d + Rule 34)

| Expectation | Detection heuristic |
|---|---|
| Rule 32(a): 7-day delay qualified as `hyväksyttävä syy` under HOL § 114 | `hyväksyttävä syy.*114\|§ 114.*hyväksyttävä` in draft body |
| Rule 32(b): Charter Art 41 candidate breach because mis-routing originated from state-issued document with identity error | `Charter\|EU.*41\|perusoikeuskirja.*41` AND `identiteetti\|nimi\|name` |
| Rule 32(c): `<actions_required>` includes evidence-gather for `Posti tracking screenshot RS846423104FI + pickup receipt` | regex `RS846423104FI` AND `tracking\|seuranta` |
| Rule 32(d): ≤80-word paragraph in any active § 114 draft citing tracking number verbatim and dates 22.4.2026, 29.4.2026, 6.5.2026 | tracking number string + all 3 dates present in single paragraph |
| Rule 34: `identity_errors_pattern[]` increment with `{type: name_transliteration, doc: posti_envelope, value_observed: "Dimitri", value_expected: "Dmitri"}` | regex in `<memory_update>` block: `name_transliteration` AND `Dimitri` AND `Dmitri` |

### Brevity guard
The §114 paragraph from Rule 32(d) MUST be ≤80 words. If runner can isolate that paragraph, count words.

## v1.1-final fallback
- May mention the delay narratively but will not bind it to HOL § 114 with paragraph-form citation.
- Will not increment identity-pattern memory.

## PASS criteria
1. Tracking number `RS846423104FI` appears in output.
2. All 3 dates (22.4.2026, 29.4.2026, 6.5.2026) appear in output.
3. `HOL § 114` (or `§ 114`) cited as legal basis.
4. `<memory_update>` includes `name_transliteration` increment.

## Anti-PASS
- Output that brushes off the delay as "minor inconvenience".
- Output that misses the Charter Art 41 / state-document angle (Rule 32b) — owner relies on that for KHO erityisen painava syy framing.
