// citation_enforcement.ts — Phase 2 Pkg 2 hardening (fail-closed verifier).
// -----------------------------------------------------------------------------
// The grounding verifier (citation_grounder.ts) only handles the marker side:
// when the model emits `[[ref:TLS:88]]`, it checks whether a chunk for that
// (act, paragraph) was retrieved this turn and assigns `verified/unverified/
// historical` status. But the verifier is SILENT on a different failure mode:
// the model can write a bare law citation like "TLS § 88" or "Direktiiv
// 96/9/EÜ" WITHOUT emitting any marker at all. The grounder sees no marker,
// returns `citations: []`, and the user sees an unverifiable law claim with
// no red badge — exactly the hallucination footgun this whole pipeline was
// supposed to close.
//
// This module fills that gap. It scans the reply text for known law-citation
// shapes (Estonian act abbreviations + §/lg numbers, EU directive codes,
// ECHR articles) and, for every shape it finds, checks whether the same
// (act, paragraph) is covered by a `[[ref:...:...]]` marker elsewhere in
// the reply. If a paragraph-level citation lacks a marker, we treat it as
// a hallucination and either:
//   • STRIP the bare citation (replacement: act name kept, § number removed)
//   • or RECORD a violation (caller chooses what to do with the text).
//
// Generic mentions are explicitly NOT touched. "vastavalt seadusele",
// "üürilepingu seadustes on sätestatud", "Estonian Employment Contracts Act
// generally allows..." — none of these trigger enforcement because they
// do not name a specific paragraph. Only `<ACT> § <NUMBER>` shapes (and
// EU directive / ECHR equivalents) are gated.
//
// Pure module — same constraints as citation_grounder.ts (no I/O, no Deno
// globals, pure regex). Imported by claude-proxy/index.ts post-verifier.
//
// Design doc: docs/architecture/phase2-pkg2-citations.md §11 (fail-closed
// enforcement, added 2026-05-11).
// -----------------------------------------------------------------------------

import {
  CITATION_MARKER_PATTERN,
  type Citation,
} from "./citation_grounder.ts";

// ── 1. Patterns ──────────────────────────────────────────────────────────────

/** Estonian law abbreviations that the model is instructed to cite as
 *  `<ABBR> § <NUM>` (see services/system_prompts.dart). Lowercase keys
 *  match the act_slug values in the law_chunks table.
 *
 *  Curated from the system prompt's "Estonia" instruction block (line
 *  480 of system_prompts.dart). Order is irrelevant — we build a single
 *  alternation regex from the keys.
 *
 *  Adding a new act here is non-breaking as long as the slug matches
 *  law_chunks.act_slug; tests should be extended in parallel. */
export const ESTONIAN_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  // [user-visible abbreviation, lowercase act_slug for marker comparison]
  ["TLS", "tls"],
  ["VÕS", "võs"],
  ["VOS", "vos"], // ASCII-folded variant some models emit
  ["VõS", "võs"],
  ["KarS", "kars"],
  ["KARS", "kars"],
  ["PKS", "pks"],
  ["TsÜS", "tsüs"],
  ["TSÜS", "tsüs"],
  ["TsUS", "tsus"], // ASCII-folded
  ["TsMS", "tsms"],
  ["TSMS", "tsms"],
  ["KrMS", "krms"],
  ["KRMS", "krms"],
  ["HMS", "hms"],
  ["HKMS", "hkms"],
  ["PärS", "pärs"],
  ["PARS", "pars"],
  ["AsjS", "asjs"],
  ["ASJS", "asjs"],
  ["MKS", "mks"],
  ["TuMS", "tums"],
  ["TUMS", "tums"],
  ["KMS", "kms"],
  ["ÄS", "äs"],
  ["AS", "as"],
  ["IKS", "iks"],
  ["LS", "ls"],
  ["LKindlS", "lkindls"],
  ["LKINDLS", "lkindls"],
  ["VõrdKS", "võrdks"],
  ["VORDKS", "vordks"],
  ["VMS", "vms"],
]);

/** Sorted alternation built from the keys above. Longest-first so
 *  `LKindlS` is tried before `LS` (avoids LS swallowing the L of
 *  LKindlS). RegExp-escaped per char — abbreviations are alphanumeric
 *  + the `Õ`/`Ä`/`Ü` glyphs, none of which are regex metas. */
const ABBREV_ALTERNATION = Array.from(ESTONIAN_LAW_ABBREVS.keys())
  .sort((a, b) => b.length - a.length)
  .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  .join("|");

/** Finnish law abbreviations (Phase 2 Pkg 1, 2026-05-11). Added in
 *  parallel with the Finlex statute ingest. The lowercase value is the
 *  `act_slug` that the Finnish corpus uses; per the design doc §6 those
 *  slugs are prefixed `fi-` to avoid collisions with Estonian acts that
 *  share an abbreviation (e.g. Estonian Töölepingu seadus and Finnish
 *  Työsopimuslaki both abbreviate as TLS/TSL).
 *
 *  When a future Finnish act is added, register it here AND in
 *  `services/system_prompts.dart` so the model is taught to cite it
 *  AND the enforcer can catch un-grounded mentions.
 *
 *  Variants: Finnish legalese uses a mix of upper-case acronyms (TSL)
 *  and CamelCase forms (TyöAikaL). We register both common shapes for
 *  each act so a model regression to either form is still caught. */
export const FINNISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  // Phase 1 priority acts (matches PHASE_1_ACTS in scripts/scrape_finlex.ts)
  ["TSL", "fi-tsl"],          // Työsopimuslaki 55/2001
  ["UL", "fi-ul"],            // Ulkomaalaislaki 301/2004
  ["HL", "fi-hl"],            // Hallintolaki 434/2003
  ["LOHA", "fi-loha"],        // Laki oikeudenkäynnistä hallintoasioissa 808/2019
  ["HOL", "fi-loha"],         // Alias the model sometimes uses ("hallinto-oikeuslaki")
  ["AL", "fi-al"],            // Avioliittolaki 234/1929
  ["LHL", "fi-lhl"],          // Laki lapsen huollosta ja tapaamisoikeudesta 361/1983
  ["RL", "fi-rl"],            // Rikoslaki 39/1889
  ["KSL", "fi-ksl"],          // Kuluttajansuojalaki 38/1978
  ["VJL", "fi-vjl"],          // Velkajärjestelylaki 57/1993
  ["VjL", "fi-vjl"],          // CamelCase variant
  ["VKL", "fi-vkl"],          // Vahingonkorvauslaki 412/1974
  ["VahKL", "fi-vkl"],        // Common longer spelling
  ["AHVL", "fi-ahvl"],        // Laki asuinhuoneiston vuokrauksesta 481/1995
  // Phase 2 acts (registered ahead of ingest so the enforcer is ready)
  ["OYL", "fi-oyl"],          // Osakeyhtiölaki
  ["AOYL", "fi-aoyl"],        // Asunto-osakeyhtiölaki
  ["TyöAikaL", "fi-tyoaika"],  // Työaikalaki
  ["VuosilomaL", "fi-vuosiloma"], // Vuosilomalaki
  ["YhdenvertaisuusL", "fi-yhdvl"], // Yhdenvertaisuuslaki
  ["KansL", "fi-kansl"],       // Kansalaisuuslaki
]);

/** Sorted alternation for Finnish abbreviations. Longest-first so
 *  `YhdenvertaisuusL` is tried before `L` (no risk currently since `L`
 *  is not registered, but the pattern is defensive). */
const FINNISH_ABBREV_ALTERNATION = Array.from(FINNISH_LAW_ABBREVS.keys())
  .sort((a, b) => b.length - a.length)
  .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  .join("|");

// ─── Multi-jurisdiction abbreviation tables (2026-05-19 EU launch) ──────────
//
// These cover the top 10 EU member-state jurisdictions Advocat needs to ship
// against. They are kept STRICTLY SEPARATE from FI/EE so that:
//   1. The Estonian / Finnish enforcement branches (`ee_bare_paragraph`,
//      `fi_bare_paragraph`) are bit-for-bit unchanged. The CI tests pinned
//      against those branches keep passing.
//   2. A future per-country tuning round can target a single country's
//      table without rebuilding the global regex.
//
// Each map's value is the lowercase `act_slug` the corpus uses for that act.
// Slugs follow the pattern `<country>-<short>` (e.g. `de-bgb`, `fr-cc`,
// `pl-kc`) — same convention the Finnish corpus already uses (`fi-tsl`).
// When a country starts ingesting real chunks, the migrator script should
// stamp the same slug into `law_chunks_v2.act_slug` so the marker layer
// matches the same key.

/** Germany — civil/criminal/commercial codes most likely to appear in
 *  Advocat replies. Citation form: `§ 433 BGB`, `§ 242 StGB`. */
export const GERMAN_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["BGB", "de-bgb"],           // Bürgerliches Gesetzbuch (civil)
  ["StGB", "de-stgb"],         // Strafgesetzbuch (criminal)
  ["ZPO", "de-zpo"],           // Zivilprozessordnung (civil procedure)
  ["StPO", "de-stpo"],         // Strafprozessordnung (criminal procedure)
  ["HGB", "de-hgb"],           // Handelsgesetzbuch (commercial)
  ["AktG", "de-aktg"],         // Aktiengesetz (corporate)
  ["GmbHG", "de-gmbhg"],       // GmbH-Gesetz (limited-liability)
  ["GG", "de-gg"],             // Grundgesetz (constitution)
  ["AO", "de-ao"],             // Abgabenordnung (tax procedure)
  ["EStG", "de-estg"],         // Einkommensteuergesetz (income tax)
  ["UStG", "de-ustg"],         // Umsatzsteuergesetz (VAT)
  ["BetrVG", "de-betrvg"],     // Betriebsverfassungsgesetz (works councils)
  ["KSchG", "de-kschg"],       // Kündigungsschutzgesetz (dismissal protection)
  ["BDSG", "de-bdsg"],         // Bundesdatenschutzgesetz (data protection)
]);

/** France — codes (CC = code civil, CP = code pénal, CPC = code de procédure
 *  civile). French citations frequently combine `art. L. 121-1` or
 *  `article 1240 C. civ.`. */
export const FRENCH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["C.civ.", "fr-cc"],          // Code civil
  ["C. civ.", "fr-cc"],
  ["CC", "fr-cc"],
  ["Code civil", "fr-cc"],
  ["C. pén.", "fr-cp"],         // Code pénal
  ["C.pén.", "fr-cp"],
  ["CP", "fr-cp"],
  ["Code pénal", "fr-cp"],
  ["CPC", "fr-cpc"],            // Code de procédure civile
  ["C. proc. civ.", "fr-cpc"],
  ["CPP", "fr-cpp"],            // Code de procédure pénale
  ["C. proc. pén.", "fr-cpp"],
  ["CGI", "fr-cgi"],            // Code général des impôts (tax)
  ["C. com.", "fr-ccom"],       // Code de commerce
  ["C.com.", "fr-ccom"],
  ["C. trav.", "fr-ctrav"],     // Code du travail
  ["C.trav.", "fr-ctrav"],
  ["C. consom.", "fr-cconso"],  // Code de la consommation
  ["C.consom.", "fr-cconso"],
]);

/** Spain — civil/criminal/procedure codes. Citation form: `art. 1902 CC`
 *  or `artículo 248 CP`. */
export const SPANISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["CC", "es-cc"],              // Código Civil
  ["C.c.", "es-cc"],
  ["Cc", "es-cc"],
  ["CP", "es-cp"],              // Código Penal
  ["C.P.", "es-cp"],
  ["LEC", "es-lec"],            // Ley de Enjuiciamiento Civil
  ["LECrim", "es-lecrim"],      // Ley de Enjuiciamiento Criminal
  ["LOPJ", "es-lopj"],          // Ley Orgánica del Poder Judicial
  ["ET", "es-et"],              // Estatuto de los Trabajadores
  ["LGT", "es-lgt"],            // Ley General Tributaria
  ["LGSS", "es-lgss"],          // Ley General de la Seguridad Social
  ["CE", "es-ce"],              // Constitución Española
  ["LSC", "es-lsc"],            // Ley de Sociedades de Capital
]);

/** Italy — civil/criminal codes. Italian convention is lowercase abbrevs
 *  (`art. 2043 c.c.`, `art. 575 c.p.`). */
export const ITALIAN_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["c.c.", "it-cc"],            // codice civile
  ["cc", "it-cc"],
  ["C.C.", "it-cc"],
  ["c.p.", "it-cp"],            // codice penale
  ["cp", "it-cp"],
  ["C.P.", "it-cp"],
  ["c.p.c.", "it-cpc"],         // codice di procedura civile
  ["cpc", "it-cpc"],
  ["c.p.p.", "it-cpp"],         // codice di procedura penale
  ["cpp", "it-cpp"],
  ["Cost.", "it-cost"],         // Costituzione
  ["TUIR", "it-tuir"],          // Testo unico delle imposte sui redditi
  ["TUB", "it-tub"],            // Testo unico bancario
]);

/** Poland — KC = Kodeks cywilny, KK = Kodeks karny, KPC = Kodeks postępowania
 *  cywilnego, KSH = Kodeks spółek handlowych. Citation form:
 *  `art. 415 KC`, `art. 148 KK`. */
export const POLISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["KC", "pl-kc"],              // Kodeks cywilny
  ["k.c.", "pl-kc"],
  ["KK", "pl-kk"],              // Kodeks karny
  ["k.k.", "pl-kk"],
  ["KPC", "pl-kpc"],            // Kodeks postępowania cywilnego
  ["k.p.c.", "pl-kpc"],
  ["KPK", "pl-kpk"],            // Kodeks postępowania karnego
  ["k.p.k.", "pl-kpk"],
  ["KSH", "pl-ksh"],            // Kodeks spółek handlowych
  ["k.s.h.", "pl-ksh"],
  ["KP", "pl-kp"],              // Kodeks pracy
  ["k.p.", "pl-kp"],
  ["KRO", "pl-kro"],            // Kodeks rodzinny i opiekuńczy
  ["k.r.o.", "pl-kro"],
  ["Ord. pod.", "pl-op"],       // Ordynacja podatkowa
  ["Konstytucja", "pl-konst"],
]);

/** Czech Republic — OZ = občanský zákoník (89/2012 Sb.), TZ = trestní
 *  zákoník. Citation form: `§ 2913 OZ`, `§ 175 TZ`. */
export const CZECH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["OZ", "cz-oz"],              // občanský zákoník
  ["TZ", "cz-tz"],              // trestní zákoník
  ["TrZ", "cz-tz"],             // alt abbreviation
  ["OSŘ", "cz-osr"],            // občanský soudní řád (civil procedure)
  ["TŘ", "cz-tr"],              // trestní řád (criminal procedure)
  ["ZOK", "cz-zok"],            // zákon o obchodních korporacích
  ["ZP", "cz-zp"],              // zákoník práce
  ["LZPS", "cz-lzps"],          // Listina základních práv a svobod
]);

/** Slovakia — mirrors Czech abbreviations but with slovak slugs. OZ =
 *  Občiansky zákonník, TZ = Trestný zákon. */
export const SLOVAK_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["OZ", "sk-oz"],              // Občiansky zákonník
  ["TZ", "sk-tz"],              // Trestný zákon
  ["OSP", "sk-osp"],            // Občiansky súdny poriadok (old) — kept for historical refs
  ["CSP", "sk-csp"],            // Civilný sporový poriadok
  ["TP", "sk-tp"],              // Trestný poriadok
  ["ZoOK", "sk-zook"],          // Zákon o obchodných korporáciách
  ["Zákonník práce", "sk-zp"],
]);

/** Sweden — BrB = brottsbalken (criminal), JB = jordabalken (real estate),
 *  ÄB = ärvdabalken (inheritance), RB = rättegångsbalken (procedure). */
export const SWEDISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["BrB", "se-brb"],            // Brottsbalken
  ["JB", "se-jb"],              // Jordabalken
  ["ÄB", "se-ab"],              // Ärvdabalken
  ["AB", "se-ab"],              // ASCII-folded variant
  ["RB", "se-rb"],              // Rättegångsbalken (civil & criminal procedure)
  ["FB", "se-fb"],              // Föräldrabalken (family)
  ["HB", "se-hb"],              // Handelsbalken
  ["UB", "se-ub"],              // Utsökningsbalken (enforcement)
  ["RF", "se-rf"],              // Regeringsformen (constitution)
  ["LAS", "se-las"],            // Lag om anställningsskydd
]);

/** Denmark — STRFL = straffeloven (criminal), RPL = retsplejeloven
 *  (procedure). */
export const DANISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["STRFL", "dk-strfl"],        // Straffeloven
  ["STRL", "dk-strfl"],         // common shortening
  ["RPL", "dk-rpl"],            // Retsplejeloven
  ["AFTL", "dk-aftl"],          // Aftaleloven
  ["ARL", "dk-arl"],            // Arveloven
  ["EBL", "dk-ebl"],            // Ejendomsbeskatningsloven
  ["GRL", "dk-grl"],            // Grundloven (constitution)
  ["FE", "dk-fe"],              // Funktionærloven (employees)
]);

/** Netherlands — BW = Burgerlijk Wetboek (civil, divided into 7+ books),
 *  Sr = Wetboek van Strafrecht (criminal), Sv = Wetboek van Strafvordering
 *  (criminal procedure), Rv = Wetboek van Burgerlijke Rechtsvordering
 *  (civil procedure). Citation form: `art. 6:162 BW`, `art. 287 Sr`. */
export const DUTCH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  ["BW", "nl-bw"],              // Burgerlijk Wetboek
  ["Sr", "nl-sr"],              // Wetboek van Strafrecht
  ["Sv", "nl-sv"],              // Wetboek van Strafvordering
  ["Rv", "nl-rv"],              // Wetboek van Burgerlijke Rechtsvordering
  ["WvK", "nl-wvk"],            // Wetboek van Koophandel
  ["AWB", "nl-awb"],            // Algemene wet bestuursrecht
  ["Gw", "nl-gw"],              // Grondwet
  ["AWR", "nl-awr"],            // Algemene wet inzake rijksbelastingen
]);

/** Combined map of every multi-jurisdiction abbreviation, keyed by the
 *  surface form the model emits. For ambiguous keys (e.g. `CC` = either
 *  French Code civil OR Spanish Código Civil OR Polish KC alias), the
 *  first registered entry wins. Specific-country disambiguation happens
 *  at the system-prompt layer (jurisdiction hint) — this map is only the
 *  fallback recogniser. */
const MULTI_JURIS_TABLES: ReadonlyArray<readonly [string, ReadonlyMap<string, string>]> = [
  ["de", GERMAN_LAW_ABBREVS],
  ["fr", FRENCH_LAW_ABBREVS],
  ["es", SPANISH_LAW_ABBREVS],
  ["it", ITALIAN_LAW_ABBREVS],
  ["pl", POLISH_LAW_ABBREVS],
  ["cz", CZECH_LAW_ABBREVS],
  ["sk", SLOVAK_LAW_ABBREVS],
  ["se", SWEDISH_LAW_ABBREVS],
  ["dk", DANISH_LAW_ABBREVS],
  ["nl", DUTCH_LAW_ABBREVS],
];

/** Lookup helper: surface-form → act_slug, scanning every country table in
 *  registration order. Returns `null` when the abbreviation is unknown.
 *  Used by the multi-jurisdiction enforcement branch below. Exposed for
 *  tests so we can pin "BGB → de-bgb" / "KC → pl-kc" mappings without
 *  re-running the regex pipeline. */
export function resolveMultiJurisAbbrev(
  surface: string,
): { country: string; act_slug: string } | null {
  if (!surface) return null;
  for (const [country, table] of MULTI_JURIS_TABLES) {
    const hit = table.get(surface);
    if (hit) return { country, act_slug: hit };
  }
  return null;
}

/** Flat set of every multi-jurisdiction surface form, longest-first so a
 *  regex alternation built from this list never partially-matches a longer
 *  abbreviation. */
const MULTI_JURIS_SURFACE_FORMS: string[] = (() => {
  const all = new Set<string>();
  for (const [, table] of MULTI_JURIS_TABLES) {
    for (const k of table.keys()) all.add(k);
  }
  return Array.from(all).sort((a, b) => b.length - a.length);
})();

const MULTI_JURIS_ABBREV_ALTERNATION = MULTI_JURIS_SURFACE_FORMS
  .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  .join("|");

/** Estonian bare-paragraph citation regex.
 *
 *  Shape: `<ABBR> § <NUM>` with optional `lg <NUM>`/`p <NUM>`/`-<NUM>`
 *  paragraph extensions. The § symbol is REQUIRED — generic mentions
 *  like "TLS reguleerib töösuhteid" don't carry §, so they pass through
 *  untouched.
 *
 *  Capture groups:
 *    1 — act abbreviation (e.g. "TLS", "KarS")
 *    2 — paragraph number (e.g. "88", "88-1", "5a")
 *
 *  Word boundary handling: we use a lookbehind/lookahead pair (`(?<!\w)`,
 *  `(?!\w)`) instead of `\b` because `Õ`/`Ä`/`Ü` aren't word characters
 *  in JS regex `\w` semantics. */
export const BARE_ESTONIAN_CITATION_PATTERN = new RegExp(
  `(?<![A-Za-zÕÄÜõäü0-9])(${ABBREV_ALTERNATION})\\s*§\\s*([0-9]+(?:[a-z]?(?:[-–][0-9]+)?))(?:\\s*lg\\s*[0-9]+)?(?:\\s*p\\s*[0-9]+)?`,
  "gu",
);

/** Finnish bare-paragraph citation regex (Phase 2 Pkg 1, 2026-05-11).
 *
 *  Finnish statutes are organised as `<chapter> luku <section> §`. The two
 *  common shapes the model emits in chat are:
 *    1. `TSL 7 luku 3 §` — abbreviation first, then chapter+section.
 *    2. `7 luku 3 § TSL` — chapter+section first, then abbreviation.
 *    3. `TSL § 7-3`     — compact slug form (chapter-section after §).
 *    4. `Rikoslaki 21 luku 1 §` — full act name + chapter/section.
 *
 *  All four shapes have a `§` glyph and a `luku` (chapter) marker OR a
 *  chapter-section compound after `§`. Generic mentions like `TSL
 *  reguloi työsopimuksia` carry no `§`, so they pass through untouched.
 *
 *  We emit ONE pattern with two alternatives (abbreviation-first and
 *  chapter-first), each capturing 3 groups: act abbrev, chapter (may be
 *  blank), section. The post-processor normalises `chapter-section` so
 *  `act_slug:paragraph` matches the corpus form (`fi-tsl:7-3`).
 *
 *  Capture groups (numbered across all alternations):
 *    Branch A (abbrev first):
 *      1 — act abbreviation
 *      2 — chapter number (optional)
 *      3 — section number
 *    Branch B (chapter first):
 *      4 — chapter number
 *      5 — section number
 *      6 — act abbreviation
 *    Branch C (compact slug after §):
 *      7 — act abbreviation
 *      8 — compound (e.g. "7-3" or "26")
 *
 *  Word-boundary handling uses `(?<![A-Za-zäöÄÖ0-9])` / `(?![A-Za-zäöÄÖ0-9])`
 *  because Finnish abbreviations contain Latin letters only but the
 *  surrounding text may use `ä`/`ö` glyphs that JS `\w` does not include. */
export const BARE_FINNISH_CITATION_PATTERN = new RegExp(
  // Branch A: `TSL 7 luku 3 §`  (chapter+section after abbreviation)
  `(?<![A-Za-zäöÄÖ0-9])(${FINNISH_ABBREV_ALTERNATION})\\s+(\\d+)\\s*luku\\s+(\\d+)\\s*§` +
  `|` +
  // Branch B: `7 luku 3 § TSL`  (abbreviation after chapter+section)
  `(?<![A-Za-zäöÄÖ0-9])(\\d+)\\s*luku\\s+(\\d+)\\s*§\\s*(${FINNISH_ABBREV_ALTERNATION})(?![A-Za-zäöÄÖ0-9])` +
  `|` +
  // Branch C: `TSL § 7-3` or `TSL § 26` (compact slug, chapter-section
  // compound or bare section number after the §)
  `(?<![A-Za-zäöÄÖ0-9])(${FINNISH_ABBREV_ALTERNATION})\\s*§\\s*(\\d+(?:-\\d+)?)(?![A-Za-zäöÄÖ0-9])`,
  "gu",
);

/** EU directive citation regex.
 *
 *  Common shapes the model emits:
 *    • "Direktiiv 96/9/EÜ artikkel 5"
 *    • "Directive 2019/1152, Article 5"
 *    • "Direktiivi 2002/58/EU art 5"
 *    • "EU Directive 2019/1152 (2019/1152/EU)"
 *    • "Richtlinie 2008/115/EG Artikel 5"           — DE
 *    • "directive 2008/115/CE article 5"            — FR
 *    • "direttiva 96/9/CE articolo 5"               — IT
 *    • "directiva 2008/115/CE artículo 5"           — ES
 *    • "dyrektywa 2008/115/WE artykuł 5"            — PL
 *    • "směrnice 2008/115/ES článek 5"              — CZ
 *    • "smernica 2008/115/ES článok 5"              — SK
 *    • "direktiv 2008/115/EG artikel 5"             — SE / DK
 *    • "richtlijn 2008/115/EG artikel 5"            — NL
 *
 *  We match the YEAR/NUMBER + qualifier shape. The marker form for the
 *  same citation is CELEX-style: `[[ref:32019L1152:5]]`. Building the
 *  CELEX from "2019/1152" is a year-zero-padded prefix:
 *    "2019/1152" → "32019L1152"
 *    "96/9"      → "31996L0009"
 *  which we resolve in `directiveToCelex()` below.
 *
 *  Capture groups:
 *    1 — year (2 or 4 digits)
 *    2 — directive number (1-4 digits)
 *    3 — optional article number ("artikkel 5" / "art 5" / "Article 5" /
 *        "Artikel 5" / "artykuł 5" / "článek 5" / "articolo 5" / "artículo 5") */
export const BARE_EU_DIRECTIVE_PATTERN = new RegExp(
  // Directive root (multi-lingual). Word-boundaried.
  `(?<![A-Za-z0-9])` +
  `(?:Direktiivi?|Directive|Richtlinie|directive|direttiva|directiva|` +
    `dyrektywa|směrnice|smernica|direktiv|richtlijn)` +
  `\\s*(?:nr\\.?\\s*)?` +
  // Year + number
  `(\\d{2,4})/(\\d{1,4})` +
  // Optional /XX or /XXX suffix for treaty namespace (EÜ/EU/EC/EEC/EG/CE/WE/ES)
  `(?:/(?:E[ÜU]|EC|EEC|EG|CE|WE|ES))?` +
  // Optional article-or-equivalent qualifier within ~60 chars
  `(?:[^\\n]{0,60}?(?:artikkel|artikla|artikli|Artikel|artikel|artículo|` +
    `articolo|artykuł|článek|článok|art\\.?|Article)\\s*(\\d+[a-z]?))?`,
  "giu",
);

/** EU regulation citation regex (added 2026-05-19 — multi-lingual launch).
 *
 *  Common shapes:
 *    • "Regulation (EU) 2016/679 Article 17"
 *    • "Verordnung (EU) 2016/679 Artikel 17"
 *    • "Règlement (UE) 2016/679 article 17"        — FR
 *    • "Reglamento (UE) 2016/679 artículo 17"      — ES
 *    • "Regolamento (UE) 2016/679 articolo 17"     — IT
 *    • "Rozporządzenie (UE) 2016/679 artykuł 17"   — PL
 *    • "Nařízení (EU) 2016/679"                    — CZ
 *    • "Förordning (EU) 2016/679"                  — SE
 *    • "Forordning (EU) 2016/679"                  — DK
 *    • "Verordening (EU) 2016/679"                 — NL
 *    • "asetus (EU) 2016/679"                      — FI
 *    • "määrus (EL) 2016/679"                      — EE
 *
 *  Same capture-group layout as the directive pattern.
 *
 *  Note: kept as a SEPARATE constant (and a separate enforcement branch)
 *  rather than merging into BARE_EU_DIRECTIVE_PATTERN so the existing
 *  CELEX-shape logic (`L` for directive vs `R` for regulation) stays
 *  legible and the directive tests keep passing unchanged. */
export const BARE_EU_REGULATION_PATTERN = new RegExp(
  `(?<![A-Za-z0-9])` +
  `(?:Regulation|Verordnung|Règlement|R[èe]glement|Reglamento|Regolamento|` +
    `Rozporządzenie|Nařízení|Förordning|Forordning|Verordening|asetus|määrus)` +
  // Optional treaty body marker in parens (EU)/(EL)/(UE)/(EG)/(EÜ)
  `\\s*(?:\\((?:EU|EL|UE|EG|EÜ|EC)\\))?\\s*(?:nr\\.?\\s*)?` +
  `(\\d{2,4})/(\\d{1,4})` +
  `(?:/(?:E[ÜU]|EC|EEC|EG|CE|WE|ES))?` +
  `(?:[^\\n]{0,60}?(?:artikkel|artikla|artikli|Artikel|artikel|artículo|` +
    `articolo|artykuł|článek|článok|art\\.?|Article)\\s*(\\d+[a-z]?))?`,
  "giu",
);

/** Country gazette publication shapes (added 2026-05-19).
 *
 *  These are the *primary* citation form in continental case-law:
 *  Germany cites "BGBl. I S. 123", France "JORF n° 0078", Spain "BOE
 *  núm. 215", Italy "GU Serie Generale n. 123", Poland "Dz.U. 2020
 *  poz. 1234", Czech "Sb. č. 89/2012", Sweden "SFS 2008:99",
 *  Netherlands "Stb. 2020, 123". This map is exported as a regex set
 *  for downstream consumers (search, link expanders) — it does NOT
 *  yet feed into the enforcer's strip path because we don't have a
 *  matching `[[ref:...]]` marker convention for gazette refs.
 *
 *  Keys: ISO country code or gazette short-code.
 *  Values: case-insensitive regex matching the gazette shape.
 *
 *  Conservative: each pattern requires the gazette prefix + a numeric
 *  citation body so we never false-positive on "BGB" (German civil code,
 *  a completely different beast) or "GU" inside "GUest". */
export const KNOWN_GAZETTE_PATTERNS: ReadonlyMap<string, RegExp> = new Map([
  // Germany — Bundesgesetzblatt
  ["DE_BGBl", /\bBGBl\.?\s*(?:I{1,3}|Teil\s*[IVX]+)?\s*S\.?\s*\d+/giu],
  // France — Journal Officiel
  ["FR_JORF", /\bJORF\s*(?:n[°º]\s*[\d-]+|du\s+\d{1,2}[^\n]{1,20}\d{4})/giu],
  // Spain — Boletín Oficial del Estado
  ["ES_BOE", /\bBOE(?:[\s,]+(?:n[úu]m\.?|de))?\s*\d+/giu],
  // Italy — Gazzetta Ufficiale. Two common shapes:
  //   1. `G.U. Serie Generale n. 123`  (post-2008 official form)
  //   2. `G.U. n. 123`                 (compact form)
  // Both end on a numeric body. We allow an optional `Serie Generale`
  // or `S.G.` segment between the gazette marker and the n.<number>.
  // Lookbehind on letters is robust against `G\.?` boundary issues.
  ["IT_GU", /(?<![A-Za-z])G\.?\s*U\.?\s*(?:Serie\s+Generale\s*|S\.G\.\s*)?(?:n\.?\s*)?\d+/giu],
  // Poland — Dziennik Ustaw
  ["PL_DzU", /\bDz\.?\s*U\.?\s*(?:\d{4}\s*(?:r\.)?)?(?:\s*poz\.\s*\d+|\s*nr\s*\d+)/giu],
  // Czechia — Sbírka zákonů
  ["CZ_Sb", /\b(?:Sb\.|Sbírka(?:\s+zákonů)?)\s*č?\.?\s*\d+\/\d{4}/giu],
  // Slovakia — Zbierka zákonov
  ["SK_Zb", /\bZ(?:b|z)\.?\s*č?\.?\s*\d+\/\d{4}/giu],
  // Sweden — Svensk författningssamling
  ["SE_SFS", /\bSFS\s*\d{4}:\d+/giu],
  // Denmark — Lovtidende
  ["DK_Ltid", /\bLovtidende\s*(?:nr\.?|af)?\s*\d+/giu],
  // Netherlands — Staatsblad
  ["NL_Stb", /\bStb\.?\s*\d{4}(?:[,.\s]+\d+)?/giu],
]);

/** Multi-jurisdiction bare-citation regex (DE/FR/ES/IT/PL/CZ/SK/SE/DK/NL).
 *
 *  Continental citation conventions vary by country:
 *    • Germany/Austria/Czech/Slovak: `§ 433 BGB`, `§ 2913 OZ`
 *      → number FOLLOWS the § symbol, abbreviation comes after.
 *    • France/Italy/Spain/Poland/Netherlands: `art. 1902 CC`,
 *      `art. L. 121-1 C. civ.`, `art. 6:162 BW`
 *      → "art." or "article" precedes the number, abbreviation comes after.
 *    • Sweden/Denmark: `BrB 1 kap. 1 §`, `STRFL § 191`
 *      → mixed, abbreviation first or last.
 *
 *  This regex captures the dominant `<art-keyword> <section> <ABBREV>`
 *  AND `<§> <section> <ABBREV>` shapes for the registered abbreviations.
 *  We deliberately do NOT touch the simpler `<ABBREV> § <num>` shape
 *  because that overlaps with the Estonian regex (TLS § 88) and would
 *  regress FI/EE behaviour. The Estonian table takes priority on overlap;
 *  multi-juris only runs against surface forms NOT in the EE/FI tables.
 *
 *  Branches:
 *    A — `§ <num> <ABBREV>`        DE/CZ/SK style
 *    B — `art.? <num> <ABBREV>`    FR/ES/IT/PL/NL style
 *
 *  Capture groups (numbered across the two alternatives):
 *    1 — Branch A section
 *    2 — Branch A abbreviation
 *    3 — Branch B section (supports compound like "L. 121-1" or "6:162")
 *    4 — Branch B abbreviation
 *
 *  Word-boundary lookarounds use the Latin-1+European-glyph charset so
 *  `Ä`/`Ö`/`Ç`/`Ñ`/`Ł` adjacent to a match don't break matching. */
export const BARE_MULTI_JURIS_CITATION_PATTERN = new RegExp(
  // Branch A: § <num> <ABBREV>  (DE / CZ / SK)
  `(?<![A-Za-zÄÖÜäöüßÇçÑñŁłŠšŽžÁÉÍÓÚáéíóúÀàÈèÌìÒòÙù0-9])` +
  `§\\s*(\\d+(?:[a-z]?(?:[-–]\\d+)?))\\s+(${MULTI_JURIS_ABBREV_ALTERNATION})` +
  `(?![A-Za-zÄÖÜäöüßÇçÑñŁłŠšŽžÁÉÍÓÚáéíóú0-9])` +
  `|` +
  // Branch B: art./article <num> <ABBREV>  (FR / ES / IT / PL / NL)
  // Section can be plain number, alphanumeric (L. 121-1), or chapter-section
  // compound (6:162). We allow optional "L." or "R." prefix common in French
  // numbering.
  `(?<![A-Za-zÄÖÜäöüßÇçÑñŁłŠšŽžÁÉÍÓÚáéíóúÀàÈèÌìÒòÙù0-9])` +
  `(?:art(?:icle|ículo|icolo|ykuł|\\.?)|Art\\.?|ARTÍCULO|articolo)\\s+` +
  `((?:[LR]\\.?\\s*)?\\d+(?:[-–:]\\d+)?(?:[a-z])?)\\s+` +
  `(${MULTI_JURIS_ABBREV_ALTERNATION})` +
  `(?![A-Za-zÄÖÜäöüßÇçÑñŁłŠšŽžÁÉÍÓÚáéíóú0-9])`,
  "gu",
);

/** ECHR article citation. Shape: "EIÕK artikkel 6", "ECHR Article 8",
 *  "Конвенция, ст. 3". We match the most common forms.
 *
 *  Capture groups:
 *    1 — article number */
export const BARE_ECHR_PATTERN = new RegExp(
  `(?<![A-Za-z])(?:EIÕK|ECHR|ECtHR)\\s*(?:artikkel|art\\.?|Article)\\s*(\\d+[a-z]?)`,
  "giu",
);

// ── 2. Marker coverage check ─────────────────────────────────────────────────

/** Build the (act_slug:paragraph) set covered by markers in the reply.
 *  Both verified AND unverified citations count as "covered" — an
 *  unverified marker still ships through to the UI with a red badge,
 *  which is the right signal. The point of enforcement is to catch
 *  the case where NO marker was emitted at all. */
function buildMarkerCoverageSet(
  replyText: string,
): Set<string> {
  const set = new Set<string>();
  const re = new RegExp(CITATION_MARKER_PATTERN, "g");
  for (const match of replyText.matchAll(re)) {
    const [, act, para] = match;
    if (!act || !para) continue;
    set.add(`${act.toLowerCase()}:${para}`);
  }
  return set;
}

/** Convert a directive shape like "2019/1152" or "96/9" to its CELEX
 *  number (`32019L1152`, `31996L0009`). CELEX format:
 *    "3" + 4-digit year + "L" + 4-digit zero-padded number
 *  2-digit years are folded to 19xx for <50 and 20xx for ≥50 — this
 *  is the EUR-Lex convention. */
function directiveToCelex(year: string, number: string): string {
  let fullYear: string;
  if (year.length === 4) {
    fullYear = year;
  } else if (year.length === 2) {
    const y = parseInt(year, 10);
    fullYear = y < 50 ? `20${year}` : `19${year}`;
  } else {
    fullYear = year.padStart(4, "0");
  }
  const padded = number.padStart(4, "0");
  return `3${fullYear}L${padded}`;
}

// ── 3. Violation taxonomy + replacement strategy ─────────────────────────────

export type ViolationKind =
  | "ee_bare_paragraph"   // e.g. "TLS § 88" with no [[ref:TLS:88]]
  | "fi_bare_paragraph"   // e.g. "TSL 7 luku 3 §" with no [[ref:fi-tsl:7-3]]
  | "eu_bare_directive"   // e.g. "Direktiiv 96/9/EÜ artikkel 5" without marker
  | "eu_bare_regulation"  // e.g. "Verordnung (EU) 2016/679" without marker
  | "echr_bare_article"   // e.g. "ECHR Article 8" without marker
  | "multi_juris_bare_paragraph" // e.g. "§ 433 BGB" without [[ref:de-bgb:433]]
  ;

export interface CitationViolation {
  kind: ViolationKind;
  /** Exact substring that triggered the violation (verbatim from reply). */
  match: string;
  /** Lowercase act_slug we tried to match against markers. */
  act_slug: string;
  /** Paragraph / article number we expected a marker for. */
  paragraph: string;
  /** Character offset of the match in the original reply (for logging). */
  index: number;
  /** What the enforcer replaced the match with (or null = stripped wholesale). */
  replacement: string;
}

export interface EnforcementResult {
  /** Reply text after stripping bare citations that lacked markers.
   *  Identical to input when no violations were found. */
  cleanedText: string;
  /** Every violation found, in first-occurrence order. */
  violations: CitationViolation[];
}

/** Replacement strategy: keep the act abbreviation, drop the § number.
 *  Rationale: stripping the whole substring leaves a discontinuity that
 *  reads worse than a soft degradation. "TLS § 88 forbids X" becomes
 *  "TLS forbids X" — the user still sees a law mention but no longer
 *  sees a hallucinated paragraph. Down-stream UI shows a footer note
 *  ("citation was scrubbed: AI cited a paragraph it could not verify").
 *
 *  Exposed so tests can pin the exact replacement string. */
export function replacementForEstonian(actAbbrev: string): string {
  return actAbbrev;
}

/** Finnish replacement: keep the act abbreviation, drop the chapter/section
 *  reference. Same philosophy as Estonian — soft degradation reads better
 *  than a wholesale strip. */
export function replacementForFinnish(actAbbrev: string): string {
  return actAbbrev;
}

export function replacementForDirective(year: string, number: string): string {
  return `direktiiv ${year}/${number}`;
}

export function replacementForRegulation(year: string, number: string): string {
  return `regulation ${year}/${number}`;
}

export function replacementForEchr(): string {
  return "ECHR";
}

/** Multi-jurisdiction soft-strip: same philosophy as Estonian / Finnish — we
 *  keep the act abbreviation so the prose still flags the relevant code, but
 *  drop the un-verifiable paragraph number. */
export function replacementForMultiJuris(actAbbrev: string): string {
  return actAbbrev;
}

// ── 4. The enforcer ──────────────────────────────────────────────────────────

/** Scan `replyText` for bare law citations that aren't covered by a
 *  `[[ref:ACT:PARA]]` marker, and produce a cleaned version of the
 *  text with those bare citations replaced. The verifier's pre-computed
 *  `citations` array is accepted but only used for logging context;
 *  the marker coverage set is rebuilt from the reply text directly so
 *  this function is correct even when called with citations=[].
 *
 *  Pure function. Idempotent: enforce(enforce(x)) === enforce(x), provided
 *  the replacement strings themselves don't contain a § symbol.
 *
 *  Algorithm:
 *    1. Build marker-coverage set: every (act_slug:paragraph) that the
 *       model wrapped in a [[ref:...:...]] marker.
 *    2. Scan for Estonian bare citations. For each match, check the
 *       coverage set. If not covered → record violation, replace inline.
 *    3. Same for EU directives (CELEX-normalized) and ECHR articles.
 *    4. Apply replacements in reverse-index order so earlier offsets
 *       remain valid during string mutation.
 *
 *  Returns `{ cleanedText, violations }`. The caller can:
 *    • Use cleanedText (default — strip & ship).
 *    • Use violations.length > 0 to decide to retry the LLM call instead. */
export function enforceCitations(
  replyText: string,
  _citations: ReadonlyArray<Citation> = [],
): EnforcementResult {
  if (!replyText) {
    return { cleanedText: replyText ?? "", violations: [] };
  }

  const coverage = buildMarkerCoverageSet(replyText);
  const violations: CitationViolation[] = [];

  // Collect all violations first WITHOUT mutating text; then splice in
  // reverse order so indices remain valid.
  type Edit = { start: number; end: number; replacement: string };
  const edits: Edit[] = [];

  // ── 4a. Estonian abbreviations ──────────────────────────────────────────
  {
    const re = new RegExp(BARE_ESTONIAN_CITATION_PATTERN.source, "gu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const abbrev = m[1];
      const para = m[2];
      const idx = m.index ?? -1;
      if (!abbrev || !para || idx < 0) continue;
      const actSlug = ESTONIAN_LAW_ABBREVS.get(abbrev)
        ?? abbrev.toLowerCase();
      const key = `${actSlug}:${para}`;
      // ALSO accept a marker that points to the same act + a prefix
      // paragraph. e.g. "TLS § 88-1" should be considered covered if
      // the marker `[[ref:TLS:88]]` is present — the granular paragraph
      // exists inside the parent. Conservative: only accept if the
      // paragraph BEFORE the first hyphen has a marker.
      const parentPara = para.split(/[-–]/)[0];
      const parentKey = `${actSlug}:${parentPara}`;
      if (coverage.has(key) || coverage.has(parentKey)) continue;

      const replacement = replacementForEstonian(abbrev);
      // Compute the substring within the original match that corresponds
      // to "§ <num>..." — we keep the abbreviation, strip the rest.
      const abbrevEnd = idx + abbrev.length;
      edits.push({
        start: abbrevEnd,
        end: idx + fullMatch.length,
        replacement: "", // erase everything after the abbreviation
      });
      violations.push({
        kind: "ee_bare_paragraph",
        match: fullMatch,
        act_slug: actSlug,
        paragraph: para,
        index: idx,
        replacement,
      });
    }
  }

  // ── 4a-bis. Finnish abbreviations (Phase 2 Pkg 1) ───────────────────────
  // Finnish citations come in three shapes (see BARE_FINNISH_CITATION_PATTERN):
  //   A: `TSL 7 luku 3 §`  → groups [1,2,3] = (abbrev, chapter, section)
  //   B: `7 luku 3 § TSL`  → groups [4,5,6] = (chapter, section, abbrev)
  //   C: `TSL § 7-3`       → groups [7,8]   = (abbrev, chapter-section)
  //
  // The corpus stores paragraphs as `<chapter>-<section>` (e.g. "7-3") so
  // the marker key is `fi-tsl:7-3`. For branch C the section component is
  // already in the right shape ("7-3" or "26"); for A/B we synthesise it.
  {
    const re = new RegExp(BARE_FINNISH_CITATION_PATTERN.source, "gu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const idx = m.index ?? -1;
      if (idx < 0) continue;

      let abbrev: string | undefined;
      let paragraph: string | undefined;
      if (m[1] && m[3]) {
        // Branch A: TSL 7 luku 3 §
        abbrev = m[1];
        const chapter = m[2];
        paragraph = `${chapter}-${m[3]}`;
      } else if (m[6] && m[4] && m[5]) {
        // Branch B: 7 luku 3 § TSL
        abbrev = m[6];
        paragraph = `${m[4]}-${m[5]}`;
      } else if (m[7] && m[8]) {
        // Branch C: TSL § 7-3 (compound) or TSL § 26 (bare)
        abbrev = m[7];
        paragraph = m[8];
      }
      if (!abbrev || !paragraph) continue;

      const actSlug = FINNISH_LAW_ABBREVS.get(abbrev) ??
        // Fall back to lowercase-prefixed form so the key is still
        // diagnostically useful even if a future abbreviation slips
        // through. The marker won't match (correctly flagged as bare).
        `fi-${abbrev.toLowerCase()}`;
      const key = `${actSlug}:${paragraph}`;

      // Parent paragraph rule: `TSL § 7-3` is considered covered by
      // `[[ref:fi-tsl:7]]` (chapter-level marker). This mirrors the
      // Estonian `TLS § 88-1` → `[[ref:TLS:88]]` parent rule.
      const parentPara = paragraph.split(/[-–]/)[0];
      const parentKey = `${actSlug}:${parentPara}`;
      if (coverage.has(key) || coverage.has(parentKey)) continue;

      const replacement = replacementForFinnish(abbrev);
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement,
      });
      violations.push({
        kind: "fi_bare_paragraph",
        match: fullMatch,
        act_slug: actSlug,
        paragraph,
        index: idx,
        replacement,
      });
    }
  }

  // ── 4b. EU directives ───────────────────────────────────────────────────
  {
    const re = new RegExp(BARE_EU_DIRECTIVE_PATTERN.source, "giu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const year = m[1];
      const number = m[2];
      const article = m[3];
      const idx = m.index ?? -1;
      if (!year || !number || idx < 0) continue;
      const celex = directiveToCelex(year, number).toLowerCase();
      // For directives the "paragraph" is the article — if no article was
      // captured, we require a marker for ANY paragraph of this directive
      // (any [[ref:<celex>:*]] suffices). This avoids over-blocking when
      // the model says "Direktiiv 96/9/EÜ" without a specific article.
      if (!article) {
        // Generic mention without article — only flag if NO marker at all
        // for this directive. Otherwise the model has cited specific
        // articles elsewhere and this is a back-reference.
        const anyArticleCovered = Array.from(coverage).some((k) =>
          k.startsWith(`${celex}:`)
        );
        if (anyArticleCovered) continue;
        // No marker for this directive at all → still flag, but use a
        // gentler replacement (just the year/number, no "Direktiiv" word).
        edits.push({
          start: idx,
          end: idx + fullMatch.length,
          replacement: replacementForDirective(year, number),
        });
        violations.push({
          kind: "eu_bare_directive",
          match: fullMatch,
          act_slug: celex,
          paragraph: "(unspecified)",
          index: idx,
          replacement: replacementForDirective(year, number),
        });
        continue;
      }
      const key = `${celex}:${article}`;
      if (coverage.has(key)) continue;
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement: replacementForDirective(year, number),
      });
      violations.push({
        kind: "eu_bare_directive",
        match: fullMatch,
        act_slug: celex,
        paragraph: article,
        index: idx,
        replacement: replacementForDirective(year, number),
      });
    }
  }

  // ── 4b-bis. EU regulations (multi-lingual, 2026-05-19) ─────────────────
  // Mirrors directive logic but builds an `R`-flavoured CELEX
  // (`32016R0679`). We deliberately only flag here if the surface form
  // contains a regulation root (Verordnung / Regulation / Règlement / …).
  // Directives are already covered by branch 4b, and the surface forms
  // don't overlap, so no double-counting.
  {
    const re = new RegExp(BARE_EU_REGULATION_PATTERN.source, "giu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const year = m[1];
      const number = m[2];
      const article = m[3];
      const idx = m.index ?? -1;
      if (!year || !number || idx < 0) continue;
      // CELEX: regulations use `R`, year-zero-padded
      let fullYear: string;
      if (year.length === 4) {
        fullYear = year;
      } else if (year.length === 2) {
        const y = parseInt(year, 10);
        fullYear = y < 50 ? `20${year}` : `19${year}`;
      } else {
        fullYear = year.padStart(4, "0");
      }
      const padded = number.padStart(4, "0");
      const celex = `3${fullYear}R${padded}`.toLowerCase();

      if (!article) {
        // Generic regulation mention — accept if any article for this
        // regulation has a marker, otherwise soft-replace.
        const anyArticleCovered = Array.from(coverage).some((k) =>
          k.startsWith(`${celex}:`)
        );
        if (anyArticleCovered) continue;
        edits.push({
          start: idx,
          end: idx + fullMatch.length,
          replacement: replacementForRegulation(year, number),
        });
        violations.push({
          kind: "eu_bare_regulation",
          match: fullMatch,
          act_slug: celex,
          paragraph: "(unspecified)",
          index: idx,
          replacement: replacementForRegulation(year, number),
        });
        continue;
      }
      const key = `${celex}:${article}`;
      if (coverage.has(key)) continue;
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement: replacementForRegulation(year, number),
      });
      violations.push({
        kind: "eu_bare_regulation",
        match: fullMatch,
        act_slug: celex,
        paragraph: article,
        index: idx,
        replacement: replacementForRegulation(year, number),
      });
    }
  }

  // ── 4b-ter. Multi-jurisdiction (DE/FR/ES/IT/PL/CZ/SK/SE/DK/NL) ──────────
  // Continental civil-law citation forms. Resolution is purely a surface
  // lookup against MULTI_JURIS_TABLES — no DB query. The branch is
  // intentionally narrow on shape (Branch A: `§ <num> <ABBREV>`,
  // Branch B: `art. <num> <ABBREV>`) so we do not regress the Estonian
  // `<ABBREV> § <num>` enforcement above. Coverage check accepts the
  // same `act_slug:paragraph` key shape as the Estonian / Finnish
  // branches; markers stay `[[ref:de-bgb:433]]` / `[[ref:fr-cc:1240]]`.
  {
    const re = new RegExp(BARE_MULTI_JURIS_CITATION_PATTERN.source, "gu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const idx = m.index ?? -1;
      if (idx < 0) continue;

      // Branch A captures: m[1]=section, m[2]=abbrev
      // Branch B captures: m[3]=section, m[4]=abbrev
      let section: string | undefined;
      let abbrev: string | undefined;
      if (m[1] && m[2]) {
        section = m[1];
        abbrev = m[2];
      } else if (m[3] && m[4]) {
        // Normalise French L./R. prefix into the section so downstream
        // markers can match either "L121-1" or "L. 121-1".
        section = m[3].replace(/\s+/g, "").toUpperCase();
        // Lowercase the trailing letter when present.
        section = section.replace(/[A-Z]$/, (c) => c.toLowerCase());
        abbrev = m[4];
      }
      if (!abbrev || !section) continue;

      const resolved = resolveMultiJurisAbbrev(abbrev);
      if (!resolved) continue;
      const actSlug = resolved.act_slug;
      const key = `${actSlug}:${section}`;

      // Parent-paragraph rule (same as EE/FI branches): "BGB § 433-1"
      // is covered by [[ref:de-bgb:433]].
      const parentPara = section.split(/[-–:]/)[0];
      const parentKey = `${actSlug}:${parentPara}`;
      if (coverage.has(key) || coverage.has(parentKey)) continue;

      const replacement = replacementForMultiJuris(abbrev);
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement,
      });
      violations.push({
        kind: "multi_juris_bare_paragraph",
        match: fullMatch,
        act_slug: actSlug,
        paragraph: section,
        index: idx,
        replacement,
      });
    }
  }

  // ── 4c. ECHR articles ───────────────────────────────────────────────────
  {
    const re = new RegExp(BARE_ECHR_PATTERN.source, "giu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const article = m[1];
      const idx = m.index ?? -1;
      if (!article || idx < 0) continue;
      const key = `echr:${article}`;
      const altKey = `echr-${article.toLowerCase()}`;
      if (coverage.has(key) || coverage.has(altKey)) continue;
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement: replacementForEchr(),
      });
      violations.push({
        kind: "echr_bare_article",
        match: fullMatch,
        act_slug: "echr",
        paragraph: article,
        index: idx,
        replacement: replacementForEchr(),
      });
    }
  }

  // ── 4d. Apply edits in reverse-index order ──────────────────────────────
  // Deduplicate overlapping edits (highest-priority = first inserted).
  edits.sort((a, b) => a.start - b.start);
  const nonOverlapping: Edit[] = [];
  let lastEnd = -1;
  for (const e of edits) {
    if (e.start >= lastEnd) {
      nonOverlapping.push(e);
      lastEnd = e.end;
    }
  }
  nonOverlapping.sort((a, b) => b.start - a.start);
  let cleaned = replyText;
  for (const e of nonOverlapping) {
    cleaned = cleaned.slice(0, e.start) + e.replacement + cleaned.slice(e.end);
  }

  return { cleanedText: cleaned, violations };
}

/** Compact JSON-friendly summary for log lines. Keeps log volume bounded
 *  even when an attacker tries to flood violations (e.g. 100+ fake §
 *  citations in one reply). */
export function summariseViolations(
  violations: ReadonlyArray<CitationViolation>,
): { count: number; samples: Array<{ kind: ViolationKind; match: string; act_slug: string; paragraph: string }> } {
  const samples = violations.slice(0, 5).map((v) => ({
    kind: v.kind,
    match: v.match.slice(0, 80),
    act_slug: v.act_slug,
    paragraph: v.paragraph,
  }));
  return { count: violations.length, samples };
}
