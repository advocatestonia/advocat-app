# Test 27 — Esitutkintapöytäkirja parsed → Rule 35 sub-rules (a-g)

**Source spec:** track_A_v1.2_prompt.md §5 Test 27.

## v1.2-final expected (Rule 35 a-g)

| Sub-rule | Expectation | Detection heuristic |
|---|---|---|
| 35(a) | `<memory_update>: {key: counterparty_admission_engvist_p8, value: "sain hänet kaadettua maahan", confidence: high}` | `counterparty_admission_engvist` AND `kaadettua maahan` |
| 35(b) | `<triage>.CONTRADICTIONS: ETL_4_1_BREACH_asymmetric_medical_examination` AND `<user_brief>` quantifies (8 photos user, 0 lääkärinlausunto user, 1 lääkärinlausunto Engvist) | `ETL.*4.*1\|etl_4_1` AND `8 photo\|8 valokuv` AND `0 lääkärinlausunto\|ei lääkärinlausunto` |
| 35(c) | `<memory_update>: {key: pending_obligation_engvist_korvausvaatimus, value: "promised by 13.1.2026", expires_at: "2026-01-13"}` AND proactive sweeper flags non-delivery | `pending_obligation` AND `2026-01-13` AND (`expired\|umpeutunut\|ei toimitettu\|non-delivery`) |
| 35(d) | `<triage>.EVIDENCE GAPS: [KUULUSTELU_MISSING: Soinila]` | `KUULUSTELU_MISSING.*Soinila\|Soinila.*kuulustelu.*puutu` |
| 35(e) | `<memory_update>: {key: asianomistaja_status_self_declared, value: true, source: kuulustelu_5_12_2025}` | `asianomistaja_status_self_declared` AND `true` |
| 35(f) | Surface in `<user_brief>`: Liite 1 contains 4 SALASSA videos ~6 min — request defence access via ETL 4:15 (asianosaisjulkisuus) | `SALASSA\|salassa` AND `ETL 4:15\|asianosaisjulkisuus` |
| 35(g) | If disclosure block missing or substantive answers given before disclosure: `<triage>.CONTRADICTIONS: SALDUZ_VIOLATION_CANDIDATE` with reference to *Beuze v. Belgium* | `SALDUZ\|Salduz` AND (`Beuze\|Belgium`) |

## v1.1-final fallback
- Likely produces a flat narrative summary of the pöytäkirja without structured CONTRADICTIONS / EVIDENCE GAPS / memory updates.
- Will probably miss the asymmetric-medical contradiction and the Soinila gap.

## PASS criteria (must hit ≥5 of 7 sub-rules)
1. Engvist admission captured (35a).
2. Asymmetric medical contradiction surfaced (35b).
3. Pending obligation flagged as expired (35c).
4. Soinila kuulustelu gap (35d).
5. SALASSA video disclosure ask via ETL 4:15 (35f).

## Anti-PASS
- Output simply summarises the 35 pages without legal structure (this is a "flat-narrative-regression" — Rule 35 explicitly prevents it).
- Output advises user to "wait for police" without disclosure ask.
