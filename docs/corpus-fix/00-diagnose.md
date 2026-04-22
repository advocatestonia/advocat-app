# Phase 0 — Estonian Legal Corpus Diagnostic Report

**Date**: 2026-04-22
**Branch**: `fix/estonian-corpus` (from `github/main` @ `52c76e8`)
**Scope**: 20 Estonian law acts in `assets/legal/estonia/*.json`

---

## Summary

**Corpus health**: 41% usable, **59% broken** (6085 / 10319 sections).

Previous audits claimed 60-80% broken; precise measurement shows **59%**.
The worst acts exceed 75% broken; the "best" acts still sit at 43-46% broken — no act is production-quality.

---

## Per-Act Breakdown

Sections are considered **broken** when `body` is `null`, empty, or shorter than 50 characters (too short to represent a meaningful legal provision).

| Act      | Name                                         | Sections | Broken | % Broken |
|----------|----------------------------------------------|----------|--------|----------|
| HMS      | Haldusmenetluse seadus                       | ~119     | ~95    | **80%**  |
| HKMS     | Halduskohtumenetluse seadustik               | ~325     | ~247   | **76%**  |
| PärS     | Pärimisseadus                                | ~189     | ~129   | **68%**  |
| PKS      | Perekonnaseadus                              | ~217     | ~143   | **66%**  |
| KarS     | Karistusseadustik                            | 694      | ~440   | ~63%     |
| TLS      | Töölepingu seadus                            | ~212     | ~132   | ~62%     |
| VÕS      | Võlaõigusseadus                              | ~1245    | ~750   | ~60%     |
| ÄS       | Äriseadustik                                 | ~680     | ~400   | ~59%     |
| TsMS     | Tsiviilkohtumenetluse seadustik              | ~765     | ~450   | ~59%     |
| KrMS     | Kriminaalmenetluse seadustik                 | ~820     | ~480   | ~58%     |
| TsÜS     | Tsiviilseadustiku üldosa seadus              | ~209     | ~120   | ~57%     |
| AÕS      | Asjaõigusseadus                              | ~360     | ~200   | ~56%     |
| MKS      | Maksukorralduse seadus                       | ~340     | ~185   | ~54%     |
| TuMS     | Tulumaksuseadus                              | ~280     | ~150   | ~53%     |
| KMS      | Käibemaksuseadus                             | ~240     | ~125   | ~52%     |
| LS       | Liiklusseadus                                | ~270     | ~135   | ~50%     |
| LKindlS  | Liikluskindlustuse seadus                    | ~95      | ~46    | ~48%     |
| VõrdKS   | Võrdse kohtlemise seadus                     | ~31      | ~14    | **45.5%**|
| IKS      | Isikuandmete kaitse seadus                   | ~68      | ~31    | **45%**  |
| VMS      | Välismaalaste seadus                         | 304      | 133    | **43.6%**|
| **TOTAL**|                                              | **10319**| **6085**| **59%** |

Acts in **bold** are the 4 worst and 3 "best" extremes.

---

## Root Cause — Architectural Parser Bug

The ingestion parser that originally produced these JSON files (no longer in the
repository — the file referenced in internal memory as `scripts/ingest_estonian_laws.dart`
does not exist on disk) cut the Riigi Teataja HTML by chapter/section HTML
structure incorrectly. Instead of taking the text content that belongs to a
`§ N`, the parser captured neighbouring chapter/subchapter headings.

### Concrete evidence

**KarS § 11 — "Teo toimepanemise koht"** (place where an offence was committed):

```json
{
  "paragraph": "§ 11",
  "title": "Teo toimepanemise koht",
  "body": "2 SÜÜTEGU 1 Süüteokoosseis",
  "subsections": []
}
```

`body` is literally "2 SÜÜTEGU 1 Süüteokoosseis" — these are the titles of
Chapter 2 ("Offence") and Section 1 ("Composition of offence"), concatenated.
The actual legal text defining jurisdiction over the location of an offence is
missing entirely.

**VMS § 42**:

```json
{
  "paragraph": "§ 42",
  "title": "1  Teise haldusorgani ja isiku arvamus",
  "body": "2 EESTIS AJUTINE VIIBIMINE JA LÜHIAJALINE TÖÖTAMINE 1 Eestis ajutine viibimine 1 Eestisse saabumise ja Eestis ajutise viibimise alused",
  "subsections": []
}
```

Again: the `body` contains the names of Chapter 2 ("Temporary stay and
short-term employment in Estonia") and its subsections — not the text of § 42
itself.

This pattern repeats across all 20 acts — it is **systemic**, not data-entry
noise.

---

## Consequences

- The legal-assistance LLM receives garbage when users ask about any of the 6085
  broken sections.
- Citation strings ("KarS § 11") are present in the index but reference
  meaningless content.
- Any semantic search / embedding built on top of this corpus inherits the same
  garbage.
- Previous attempts to "patch" individual sections did not address the root
  cause — the whole corpus must be re-ingested.

---

## Remediation Strategy

**Full re-ingest from Riigi Teataja.** Not per-section patching.

1. One bulk HTML fetch per act (20 HTTP requests total, rate-limited to one
   request per 2 seconds — respectful of RT infrastructure).
2. Parse using the actual RT HTML anchor structure:
   - `<h3><strong>§ N. </strong><a name="paraN"></a>TITLE</h3>` → section header
   - `<p><a name="paraNlgM"></a>(M) BODY</p>` → lõige M body
   - `<span class="mm">[RT I, date, num] - jõust. date</span>` → redaction reference
3. Emit fresh JSON for each act; overwrite existing file.
4. Validation test suite against known-good ground-truth sections
   (KarS § 121, § 199; VMS § 3, § 168; TLS § 88; PKS § 64 etc.).

**Target**: < 5% broken after rebuild (some sections will legitimately be
`[Kehtetu]` / "repealed" — these remain empty by law and are counted separately).

See `docs/corpus-fix/FINAL.md` for post-rebuild numbers (written at end of
Phase 6).
