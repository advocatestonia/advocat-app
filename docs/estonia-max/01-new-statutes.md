# Agent E-1 — New Statutes Research

**Mission:** Add top-priority Estonian acts NOT yet in our corpus (existing 20:
HMS, HKMS, PKS, TLS, KarS, VMS, VÕS, PärS, VõrdKS, MKS, TuMS, KMS, TsMS,
KrMS, ÄS, IKS, LS, LKindlS, TsÜS, AsjS).

**Source:** riigiteataja.ee (official Estonian State Gazette).
**Fetched:** 2026-04-21.

## 12 acts added

| Code | Act (ET) | Act (EN) | Consolidated | Audience |
|------|----------|----------|--------------|----------|
| KodS | Kodakondsuse seadus | Citizenship Act | 2025-07-06 | high |
| VSS | Väljasõidukohustuse ja sissesõidukeelu seadus | Obligation to Leave and Prohibition on Entry Act | 2025-09-01 | critical |
| VRKS | Välismaalasele rahvusvahelise kaitse andmise seadus | Act on Granting International Protection | 2025-09-01 | critical |
| SHS | Sotsiaalhoolekande seadus | Social Welfare Act | 2026-01-09 | high |
| EhS | Ehitusseadustik | Building Code | 2026-03-28 | medium |
| PlanS | Planeerimisseadus | Planning Act | 2026-01-01 | medium |
| TTKS | Tervishoiuteenuste korraldamise seadus | Health Services Organization Act | 2026-04-01 | high |
| TKindlS | Töötuskindlustuse seadus | Unemployment Insurance Act | 2026-01-01 | high |
| RPKS | Riikliku pensionikindlustuse seadus | State Pension Insurance Act | 2025-11-01 | high |
| AutÕS | Autoriõiguse seadus | Copyright Act | 2025-10-01 | low |
| RekS | Reklaamiseadus | Advertising Act | 2026-03-16 | low |
| LKindlS2 | Liikluskindlustuse seadus | Motor Third-Party Liability Insurance Act | 2025-01-01 | medium |

**JSON files:** `assets/legal/estonia/<code>.json` — machine-readable schema
(`act`, `name`, `source`, `consolidated_version`, `sections[]`,
`appeal_deadline_days`, `audience_priority`, `cross_references[]`).

## Research highlights

**KodS:** Naturalisation requires 8 years residence (5 continuous),
B1 Estonian, constitutional knowledge exam, clean criminal record (no
intentional crimes > 1 year).

**VSS:** Deportation precept allows voluntary departure 7-30 days.
Appeal deadline only **10 days** to halduskohus — critical urgency marker.
Detention up to 18 months (2 months administrative + court extensions).

**VRKS:** Asylum examination deadline 6 months + 9 months extension
= 21 months max. Appeal of rejection: **10 days** (expedited procedure
has even shorter deadlines). Refugee permits: 3 years initial;
subsidiary protection: 1 year. Non-refoulement absolute (§ 50).
Recent constitutional ruling (2026-03-23) invalidated parts of § 7(2)
regarding de facto cohabitants from countries without legal marriage.

**SHS:** Subsistence benefit (toimetulekutoetus) structure documented.
Local government 10 working days to decide. Appeal 30 days.

**TTKS:** Emergency aid (§ 5) available to all persons on Estonian
territory regardless of insurance status. Uninsured emergency care
funded by Tervisekassa.

**TKindlS:** 2026 rates locked in: employee 1.6%, employer 0.8%.
Benefit: 60% of avg daily wage first 100 days, 40% after. Duration
180-300 days depending on contribution history.

**RPKS:** Standard retirement age 65, minimum 15 service years.
From 2027: age adjusts annually with life expectancy.

## Gaps / lower priority deferred

- **Kogumispensionide seadus** (funded pensions) — core rate info
  captured in business_tax.json
- **Notariaadiseadus** (notarial procedure) — covered indirectly via
  procedures.json
- **Advokatuuri seadus** — covered via emergency_contacts.json
  legal_aid block
- **Kohtute seadus** (Courts Act) — structure captured in
  riigikohus_landmarks.json

## Validation

25 tests in `test/legal/estonia_coverage_test.dart` all pass (see FINAL.md
for full results). Each JSON validated for:
- Valid `source` pointing to riigiteataja.ee
- ≥4 sections
- Every section has § paragraph ID + title + non-empty body
- ISO date format for `consolidated_version`
