# Agent E-4 — Deadlines & Statutes of Limitations

**Source:** multiple Estonian procedural and substantive codes.
**Fetched:** 2026-04-21.

## Critical immigration deadlines (in days)

| Action | Days | Legal basis | Authority |
|--------|-----:|-------------|-----------|
| Appeal deportation precept (VSS) | **10** | VSS | Halduskohus |
| Appeal asylum rejection (VRKS) | **10** | VRKS § 25¹ | Halduskohus |
| Appeal residence permit refusal | 30 | VMS § 123 | PPA Vaidemenetlus → Halduskohus |
| Asylum examination by PPA | 180 + 270 extension | VRKS § 18¹ | PPA |

## General court / administrative deadlines

| Action | Days | Legal basis |
|--------|-----:|-------------|
| Administrative act challenge (vaie) | 30 | HMS § 75 |
| Halduskohus complaint | 30 | HKMS § 46 |
| Appeal county court judgment | 30 | TsMS § 632 |
| Cassation to Riigikohus | 30 | TsMS § 670 |
| Appeal criminal judgment | 30 | KrMS § 319 |

## Employment

| Action | Days |
|--------|-----:|
| Challenge wrongful dismissal | 30 (TLS § 105) |
| Wage claim limitation | 1095 (3 years) |
| Labour dispute committee review | 45 |

## Civil / consumer

| Action | Days |
|--------|-----:|
| General civil limitation | 1095 (3 years; 10 years for deliberate breach) |
| Consumer defective goods warranty | 730 (2 years; 5 years for construction) |
| Consumer dispute commission filing | 1095 (3 years) |
| Online purchase withdrawal | 14 |

## Criminal

| Offence tier | Prosecution limitation |
|--------------|------------------------|
| 1st degree | 10 years (murder: no limit) |
| 2nd degree | 5 years |
| Misdemeanour | 2 years |

## Tax

| Action | Days |
|--------|-----:|
| Tax assessment limitation | 1095 (3; 5 if intentional concealment) |
| Appeal MTA decision | 30 |

## Other key deadlines

| Action | Days |
|--------|-----:|
| GDPR complaint (recommended) | 1095 (no strict statutory limit) |
| Ombudsman complaint | 365 |
| Social benefit decision appeal | 30 |
| Detailed plan public objection | 30 |
| Motor insurance claim resolution | 30 |
| Annual company report submission | 180 (6 months after year end) |

## Integration notes

- Stored in `assets/legal/estonia/deadlines.json` (27+ entries, each with
  category, case_type, days, legal_basis, authority).
- Complementary to existing `lib/services/deadline_database.dart`
  (which is pan-EU with 27 member states covered; Estonian entries
  there should be cross-checked against this authoritative list).
- Consumer law / product warranty 2-year rule confirms existing
  `EstonianLegalDatabase.deadlines` entry.

## Red-flag deadlines for AI safety

When the user mentions any of: "deportation order received",
"asylum rejected", "leaving Estonia notice" — the AI must immediately
warn about the **10-day** appeal window and advise contacting a lawyer
or Eesti Advokatuur state legal aid **today**, not tomorrow.
