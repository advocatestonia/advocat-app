# Test 25 — Käännytys-päätös in EN vs RU interpreter need (Rule 33)

**Source spec:** track_A_v1.2_prompt.md §5 Test 25.

## v1.2-final expected (Rule 33 + Rule 34)

| Expectation | Detection heuristic |
|---|---|
| Rule 33 fires; `<user_brief>` surfaces language defect as **strongest single procedural error** | `<user_brief>` contains keyword `kielivirhe\|language defect\|menettelyvirhe` early (first 200 chars of section) |
| Citation order: HL § 26 → Direktiivi 2004/38 Art 30(1) → ECHR 6.3.a → ECHR 6.3.e | all four anchors present in roughly that sequence in `<user_brief>` |
| **NO silent in-house translation** of the päätös for the user | output does NOT contain a long RU translation of the päätös body. Drafts in FI/EN advocacy register addressed to authority, not RU paraphrase to user |
| Rule 34: `identity_errors_pattern[]` increment with `{type: language_defect, doc: kaannytys_paatos, body_lang: "EN", required_lang: "RU"}` | `<memory_update>`: `language_defect` AND `EN` AND `RU` |
| `<triage>.CONTRADICTIONS` lists `LANGUAGE_DEFECT_RU_REQUIRED_EN_ISSUED` (or near-equivalent string) | regex `LANGUAGE_DEFECT.*RU.*EN\|kielivirhe.*RU.*EN` |

## v1.1-final fallback
- Likely paraphrases päätös in RU as "helpfulness" — that's the regression Rule 33 prevents.
- May mention HL § 26 but not the full Direktiivi/ECHR stack.

## PASS criteria
1. Output cites HL § 26.
2. Output cites Direktiivi 2004/38 Art 30(1) (or `Direktiivi 2004/38`).
3. Output cites ECHR 6.3 (any subset of a/e is acceptable).
4. Output does NOT contain a full RU translation of the inbound English päätös text.

## Anti-PASS (regression)
- Output begins with "Käännös venäjäksi:" or similar and translates päätös body — destroys the procedural-error claim because authority can argue the user understood it.
- Output frames the defect as user's responsibility ("you should have requested a translation").
