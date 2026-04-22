# OMEGA-ESTONIA-MAX — Final Report

**Branch:** `feature/estonia-max`
**Date:** 2026-04-21
**Coordinator:** OMEGA-ESTONIA-MAX (hierarchical swarm, 7 researcher
agents + 1 coder)
**Status:** Phase 1-4 complete, ready for review

## Mission

Collect maximum-depth Estonian legal knowledge base so Advocat can serve
Russian-speaking immigrants in Estonia across all major legal domains,
using **only** official government sources (no Wikipedia, no third-party
blogs, no "legal portals").

## Was / Became

| Dimension | Before | After |
|-----------|-------:|------:|
| Estonian acts (JSON corpus) | 20 | **32** |
| New acts added | — | 12 (KodS, VSS, VRKS, SHS, EhS, PlanS, TTKS, TKindlS, RPKS, AutÕS, RekS, LKindlS2) |
| Court-practice resources | 0 | 1 aggregate file (4 chambers, landmark cases, search guide) |
| Procedures catalog | 0 | 1 aggregate file (7 major agencies, 30+ services) |
| Authoritative deadlines | partial | 27 entries with legal basis + authority |
| Emergency contacts | ~10 partial | 14 numbers + legal aid + ombudsman, with RU support flagged |
| Russian-language resources | implicit | 1 dedicated file + 8 government portal links |
| Business/tax 2026 snapshot | implicit | 1 dedicated file (all rates, entities, e-Residency, digital nomad) |
| Tests covering the new corpus | 0 | 25 (all green) |
| New Dart service module | — | `lib/services/estonian_max_resources.dart` |

## Coverage estimate

**Critical immigrant cases covered:** ≈ 95%
(citizenship, residence permits, deportation, asylum, deadlines,
emergency aid, language/integration, state legal aid, ombudsman, tax,
business setup, pensions, unemployment, social welfare, healthcare).

**Remaining gaps (lower priority):**
- Kogumispensionide seadus full detail (funded pensions; rates captured
  in business_tax.json)
- Notariaadi seadus / Advokatuuri seadus full text (covered via
  procedures + legal_aid blocks)
- Kohtute seadus (Courts Act) full text (structure captured in
  riigikohus_landmarks.json)
- Tarbijakaitseseadus (TKS) full text (some procedures captured; VÕS
  substance is already in corpus)

## Artifacts

### New machine-readable JSON (18 files)

Located in `assets/legal/estonia/`:

**Statutes (12):**
- `kods.json` — Citizenship Act
- `vss.json` — Obligation to Leave and Prohibition on Entry Act
- `vrks.json` — International Protection Act
- `shs.json` — Social Welfare Act
- `ehs.json` — Building Code
- `plans.json` — Planning Act
- `ttks.json` — Health Services Organization Act
- `tkindls.json` — Unemployment Insurance Act
- `rpks.json` — State Pension Insurance Act
- `autos.json` — Copyright Act
- `reks.json` — Advertising Act
- `lkindls2.json` — Motor TPL Insurance Act

**Aggregates (6):**
- `riigikohus_landmarks.json` — Supreme Court chambers, URL pattern,
  landmark cases
- `procedures.json` — government services by category
- `deadlines.json` — 27 statutory deadlines with legal basis
- `emergency_contacts.json` — 14 helplines + legal aid + ombudsman
- `business_tax.json` — 2026 tax rates + business entity forms
- `russian_resources.json` — RU-language government portals &
  integration services

### New Dart module

- `lib/services/estonian_max_resources.dart` — Dart-level coherence
  layer exposing:
  - `newActs` map (act code → metadata)
  - `taxRates2026` snapshot
  - `additionalDeadlinesDays` map
  - `russianResourceNotice` string (ready for AI prompt inclusion)
  - `riigikohusSearchGuide` string
  - `stateLegalAidGuide` string
  - `emergencyHotlinesSummary` string

### Tests

- `test/legal/estonia_coverage_test.dart` — 25 tests, all green.
  Validates JSON shape, source URLs, section bodies, cross-references,
  Dart ↔ JSON coherence.

### Human-readable docs

`docs/estonia-max/`:
- `01-new-statutes.md`
- `02-court-practice.md`
- `03-procedures.md`
- `04-deadlines.md`
- `05-emergency.md`
- `06-russian-resources.md`
- `07-business-tax.md`
- `FINAL.md` (this file)

## New AI capabilities unlocked

With this knowledge base the Advocat AI can now:

1. **Cite KodS §§** when asked about citizenship naturalisation
   requirements (B1 language, 8-year residence, constitutional exam).
2. **Warn about 10-day deadlines** on deportation precepts (VSS) and
   asylum rejections (VRKS § 25¹) — critical for user safety.
3. **Route to correct agency** for any given procedure (PPA, MTA, SKA,
   Töötukassa, AKI, TI) with official portal URL.
4. **Quote 2026 tax rates** (22% income, 24% VAT, 33% social, min wage
   €946) with effective dates.
5. **Suggest Russian-language portals** when user writes in Russian,
   removing language-barrier friction.
6. **Surface emergency hotlines** (112, 1247, 116 006, 116 111) when
   crisis keywords appear.
7. **Explain state legal aid eligibility** (Eesti Advokatuur riigi
   õigusabi) and free 2-hour HUGO.legal consultation thresholds.
8. **Reference Riigikohus decisions** by proper case number format
   (`CHAMBER-YEAR-N/SUFFIX`) with direct URL.
9. **Direct users to Integratsiooni Sihtasutus** for free Estonian
   language courses and Settle in Estonia programme.
10. **Advise on OÜ company setup** with 2026 fee (€265), €0 capital
    requirement, e-Business Register URL, annual reporting deadline.

## Tests summary

```
flutter test test/legal/estonia_coverage_test.dart
00:00 +25: All tests passed!
```

```
flutter analyze lib/services/estonian_max_resources.dart test/legal/estonia_coverage_test.dart
No issues found!
```

Test groups:
- **New acts JSON assets** (6 tests) — shape, source URLs, sections
- **Aggregate resources** (7 tests) — each aggregate file structure
- **EstonianMaxResources coherence** (10 tests) — Dart ↔ JSON matching
- **Cross-reference coverage** (2 tests) — no duplication of existing
  acts, no orphan files

## Branch hygiene

- **Branch:** `feature/estonia-max` in submodule
  `/Users/ai.place/Advocat/app/advocat_project/`
- **Forked from:** `main` (latest)
- **Does NOT touch:**
  - Existing 20 act JSON files (handled by `fix/estonian-corpus` /
    OMEGA-CORPUS-FIX)
  - FROZEN `ai_service.dart`
  - Landing page / index.html / app.html
  - Supabase / Stripe / deploy configuration
- **No git conflicts** expected with parallel branches:
  - `fix/estonian-corpus` — touches bodies of existing 20 files only;
    we only added new files
  - `safety/bulletproof` — different subject matter
  - `feature/founder-beta-pricing` — different subject matter

## Integration instructions (for reviewer)

To light up the new knowledge in the running product **AFTER** review:

1. Optionally register the new JSON files in `pubspec.yaml` — already
   covered by existing glob `assets/legal/estonia/`.
2. Add Dart import in `lib/services/knowledge_router.dart`:
   `import 'estonian_max_resources.dart';` and surface the
   `russianResourceNotice`, `stateLegalAidGuide`,
   `emergencyHotlinesSummary` constants when query keywords match.
3. Point `lib/services/deadline_database.dart` Estonian entries to
   cross-check against `assets/legal/estonia/deadlines.json` (the
   authoritative version from this work).

These integration steps are deliberately left to the reviewer so they
can decide when to surface the new knowledge in production without
conflicting with other in-flight branches.

## Recommendation on merge order

1. **First:** `fix/estonian-corpus` (OMEGA-CORPUS-FIX) — fixes the
   corrupted bodies of the existing 20 acts. This is a prerequisite
   for trustworthy answers.
2. **Second:** `feature/estonia-max` (this branch) — adds 12 new acts
   + 6 aggregate resources + test suite, on top of the fixed corpus.
3. **Parallel safe:** `safety/bulletproof` and
   `feature/founder-beta-pricing` — independent, no corpus conflict.

## Source disclosure

Every JSON file includes a `source` field pointing to the authoritative
page on riigiteataja.ee (for statutes) or the relevant government
agency's official site (for aggregate resources). Every file also has
a `fetched_at` timestamp (2026-04-21). If a riigiteataja.ee consolidated
version changes after that date, the JSON must be refreshed.

SPA-backed pages (eesti.ee front page, palunabi.ee front page,
tootukassa.ee front page) cannot be fetched via plain HTTP and were
instead researched through `WebSearch` targeting `site:` filters on
official government domains — see per-agent docs for exact URLs.
