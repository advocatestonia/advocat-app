# Agent E-2 — Court Practice (Riigikohus + Lower Courts)

**Source:** riigikohus.ee/et/lahendid (official case law database).
**Fetched:** 2026-04-21.

## Riigikohus structure (4 chambers)

| Chamber (ET) | Chamber (EN) | Case number prefix | Competence |
|--------------|--------------|-------------------|------------|
| Halduskolleegium | Administrative Law | `3-` | Immigration, tax, social benefits, public procurement |
| Tsiviilkolleegium | Civil | `2-` | Contracts, property, family, inheritance, tort |
| Kriminaalkolleegium | Criminal | `1-` | Crimes, misdemeanours |
| Põhiseaduslikkuse järelevalve kolleegium | Constitutional Review | `5-` | Constitutional review of laws/treaties |

## Case search

- **Interface:** https://www.riigikohus.ee/et/lahendid
- **URL pattern:** `https://www.riigikohus.ee/et/lahendid/?asjaNr=<CASE_NO>`
- **Case number format:** `CHAMBER-YEAR-NUMBER/SUFFIX`
  (e.g. `3-24-713/36` = Admin chamber, year 2024, case 713, document 36)
- **Keyword index:** "Märksõnastik" feature on search page
- **Annual report:** https://aastaraamat.riigikohus.ee/
- **ECtHR summaries (RU-relevant):**
  https://www.riigikohus.ee/et/kohtupraktika-analuusid-ja-ulevaated/euroopa-inimoiguste-kohtu-lahendite-kokkuvotted

## Lower courts

### Maakohtud (County courts) — 4
Harju Maakohus, Pärnu Maakohus, Tartu Maakohus, Viru Maakohus.
First instance: civil, criminal, misdemeanour.

### Halduskohtud (Administrative courts) — 2
Tallinna Halduskohus, Tartu Halduskohus.
First instance: deportation, asylum, tax, social benefit disputes.

### Ringkonnakohtud (Courts of Appeal) — 2
Tallinna Ringkonnakohus, Tartu Ringkonnakohus.
Appellate instance for all first-instance courts.

## Landmark cases (immigration-focused)

### 1. Visa-free visitors' right to court challenge (2021)
- **Chamber:** Põhiseaduslikkuse järelevalve kolleegium
- **Summary:** VMS provisions denying court review of premature
  termination of visa-free stay declared unconstitutional. Right
  to apply to court for protection of rights extends to foreign
  nationals in Estonia.
- **Statutes:** VMS, PS § 15
- **Source:** https://www.riigikohus.ee/et/uudiste-arhiiv/riigikohus-valismaalasel-oigus-viisavabalt-eestis-viibimise-lopetamist-kohtus
- **Why it matters:** establishes that anyone physically present in
  Estonia can invoke judicial protection — key precedent for our
  deportation cases.

### 2. VRKS § 7(2) de facto partners (2026-03-23)
- **Chamber:** Constitutional Review
- **Summary:** Provisions of VRKS § 7(2) declared unconstitutional
  regarding de facto cohabitants from countries where legal
  marriage was impossible.
- **Why it matters:** asylum/protection family reunification
  expanded for unmarried partners.

## Research workflow recommendation for Advocat AI

When user asks about a specific legal issue:
1. Identify which chamber handles the subject (civil → 2-, admin → 3-…).
2. Use the Märksõnastik keyword index for topical search.
3. For individual case pulls, use the `asjaNr` URL pattern.
4. Annual reports (`aastaraamat.riigikohus.ee`) include thematic
   analyses — "Välismaalaste asjad halduskolleegiumi praktikas" is a
   valuable compiled volume for immigration law.

Stored in `assets/legal/estonia/riigikohus_landmarks.json` for the AI
knowledge router to consume.
