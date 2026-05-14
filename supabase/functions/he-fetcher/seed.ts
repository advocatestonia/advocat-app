// he-fetcher/seed.ts — Travaux préparatoires seed catalog (FI + EE)
// -----------------------------------------------------------------------------
// Curated list of the foundational legislative-intent documents we want
// available to the Travaux RAG path. Each entry maps a source document to
// the act_slug it explains, so the `travaux_for(act_slug, section)` RPC has
// something to return.
//
// FI side: Hallituksen esitykset (HE) for the 15 most-cited statutes in
// our case corpus. The Finlex `/fi/hallituksen-esitykset/{year}/{n}` URL
// is a stable, deterministic HTML page that always renders the HE.
// (Finlex doesn't have pre-1994 HEs digitised — those entries fail.)
//
// EE side: eelnõud + seletuskirjad from the Riigikogu eelnõude infosüsteem.
// URL pattern: https://www.riigikogu.ee/tegevus/eelnoud/eelnou/{uuid}/slug
// The {uuid} is the canonical Riigikogu bill UUID. UUIDs were discovered
// via api.riigikogu.ee/api/volumes/drafts?mark=N&membership=K (2026-05-14).
// The worker post-fetches the HTML page, extracts the first "Seletuskiri
// pdf" or "Algtekst" /download/{guid} link, then fetches that PDF.
//
// IMPORTANT — provenance:
//   The HE / eelnõu numbers below are the ones the consilium picked as
//   "highest-leverage" for Advocat's actual case mix. Some of them are
//   the ORIGINAL bill (e.g. HE 217/1995 vp for the Hallintolaki) and
//   some are AMENDMENT bills (e.g. HE 134/2003 vp for HOL §114 — the
//   restoration of forfeited time-limit, our Sulga §114 KHO angle).
//   Where the consilium spec called out a specific § interpretation,
//   we link to the bill that introduced or last meaningfully revised it.
//
// To keep the seed file self-contained, each row is the smallest data the
// worker needs:
//   { source_id, doc_kind, doc_number, year, related_act_slug, title, url }
// `section_ref` is intentionally null at seed time — Sonnet figures it out
// per chunk after fetching, because a single HE typically explains many §§.
// -----------------------------------------------------------------------------

export interface TravauxSeed {
  /** Stable identifier used as ingest_jobs.source_id (idempotency key). */
  source_id: string;
  /** HE / eelnõu / seletuskiri / VN. */
  doc_kind: "HE" | "eelnõu" | "seletuskiri" | "VN";
  /** Human-readable doc number (e.g. "HE 217/1995 vp", "324 SE"). */
  doc_number: string;
  /** Publication year — for tstzrange ordering + UI display. */
  year: number;
  /** act_slug the doc explains (matches law_chunks_v2.act_slug). */
  related_act_slug: string;
  /** Short human title. */
  title: string;
  /** Direct PDF / HTML URL. */
  url: string;
  /** Jurisdiction — 'fi' or 'ee'. */
  jurisdiction: "fi" | "ee";
}

// -----------------------------------------------------------------------------
// FI — 15 Hallituksen esitykset for top-cited statutes
// -----------------------------------------------------------------------------
// Finlex HE pages: https://www.finlex.fi/fi/hallituksen-esitykset/{year}/{n}
// (verified 2026-05-14: 12/15 work; pre-1994 HEs are not in Finlex).
export const FI_HE_SEEDS: TravauxSeed[] = [
  {
    source_id: "fi-he-94-1993",
    doc_kind: "HE",
    doc_number: "HE 94/1993 vp",
    year: 1993,
    related_act_slug: "fi-rikoslaki",
    title:
      "Hallituksen esitys rikoslainsäädännön kokonaisuudistuksen toisen vaiheen käsittäviksi rikoslain ja eräiden muiden lakien muutoksiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/1993/94",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-271-2004",
    doc_kind: "HE",
    doc_number: "HE 271/2004 vp",
    year: 2004,
    related_act_slug: "fi-rol",
    title:
      "Hallituksen esitys oikeudenkäynnistä rikosasioissa annetun lain muuttamisesta",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2004/271",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-15-1990-ok",
    doc_kind: "HE",
    doc_number: "HE 15/1990 vp",
    year: 1990,
    related_act_slug: "fi-ok",
    title:
      "Hallituksen esitys riita-asiain oikeudenkäyntimenettelyn uudistamista alioikeuksissa koskevaksi lainsäädännöksi (oikeudenkäymiskaari)",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/1990/15",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-217-1995",
    doc_kind: "HE",
    doc_number: "HE 217/1995 vp",
    year: 1995,
    related_act_slug: "fi-hol",
    title:
      "Hallituksen esitys laiksi hallintolainkäytöstä ja siihen liittyväksi lainsäädännöksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/1995/217",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-226-2009-oho",
    doc_kind: "HE",
    doc_number: "HE 226/2009 vp",
    year: 2009,
    related_act_slug: "fi-oho",
    title:
      "Hallituksen esitys laeiksi oikeudenkäynnin viivästymisen hyvittämisestä ja hallintolainkäyttölain muuttamisesta",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2009/226",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-28-2003-ulkl",
    doc_kind: "HE",
    doc_number: "HE 28/2003 vp",
    year: 2003,
    related_act_slug: "fi-ulkomaalaislaki",
    title: "Hallituksen esitys ulkomaalaislaiksi ja eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2003/28",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-224-2010-poll",
    doc_kind: "HE",
    doc_number: "HE 224/2010 vp",
    year: 2010,
    related_act_slug: "fi-poliisilaki",
    title: "Hallituksen esitys poliisilaiksi sekä eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2010/224",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-222-2010-etl",
    doc_kind: "HE",
    doc_number: "HE 222/2010 vp",
    year: 2010,
    related_act_slug: "fi-esitutkintalaki",
    title:
      "Hallituksen esitys esitutkinta- ja pakkokeinolainsäädännön uudistamiseksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2010/222",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-222-2010-pkl",
    doc_kind: "HE",
    doc_number: "HE 222/2010 vp",
    year: 2010,
    related_act_slug: "fi-pakkokeinolaki",
    title:
      "Hallituksen esitys esitutkinta- ja pakkokeinolainsäädännön uudistamiseksi (pakkokeinolaki)",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2010/222",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-187-1973-vahl",
    doc_kind: "HE",
    doc_number: "HE 187/1973 vp",
    year: 1973,
    related_act_slug: "fi-vahingonkorvauslaki",
    title: "Hallituksen esitys vahingonkorvausta koskevaksi lainsäädännöksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/1973/187",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-192-2005-rvl",
    doc_kind: "HE",
    doc_number: "HE 192/2005 vp",
    year: 2005,
    related_act_slug: "fi-rikosvahinkolaki",
    title:
      "Hallituksen esitys rikosvahinkolaiksi ja eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2005/192",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-1-1998-pl",
    doc_kind: "HE",
    doc_number: "HE 1/1998 vp",
    year: 1998,
    related_act_slug: "fi-perustuslaki",
    title: "Hallituksen esitys uudeksi Suomen Hallitusmuodoksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/1998/1",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-19-2014-yvl",
    doc_kind: "HE",
    doc_number: "HE 19/2014 vp",
    year: 2014,
    related_act_slug: "fi-yhdenvertaisuuslaki",
    title:
      "Hallituksen esitys yhdenvertaisuuslaiksi ja eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2014/19",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-157-2000-tsl",
    doc_kind: "HE",
    doc_number: "HE 157/2000 vp",
    year: 2000,
    related_act_slug: "fi-tyosopimuslaki",
    title: "Hallituksen esitys työsopimuslaiksi ja eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2000/157",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-218-2008-ksl",
    doc_kind: "HE",
    doc_number: "HE 218/2008 vp",
    year: 2008,
    related_act_slug: "fi-kuluttajansuojalaki",
    title:
      "Hallituksen esitys laiksi kuluttajansuojalain muuttamisesta ja eräiksi siihen liittyviksi laeiksi",
    url: "https://www.finlex.fi/fi/hallituksen-esitykset/2008/218",
    jurisdiction: "fi",
  },
];

// -----------------------------------------------------------------------------
// EE — 15 eelnõud / seletuskirjad for top EE statutes
// -----------------------------------------------------------------------------
// Riigikogu's eelnõude infosüsteem assigns each bill a numeric SE mark and
// a coosseis (parliamentary term) number. UUIDs below were resolved via
// api.riigikogu.ee/api/volumes/drafts?mark=N&membership=K (2026-05-14).
//
// URL points to the bill landing page; the worker resolves the actual
// Seletuskiri / Algtekst PDF /download/{guid} from that page.
//
// Where the consilium spec called for a specific § interpretation, the
// linked bill is the one that introduced or last meaningfully revised the
// statute in question.
// -----------------------------------------------------------------------------
export const EE_EELNOU_SEEDS: TravauxSeed[] = [
  {
    source_id: "ee-eelnou-119-se-ix",
    doc_kind: "eelnõu",
    doc_number: "119 SE IX",
    year: 2001,
    related_act_slug: "ee-karistusseadustik",
    title: "Karistusseadustiku eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/5c321fb1-dc00-3e2a-aef2-a88bef6d0f5c/karistusseadustik",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-594-se-ix",
    doc_kind: "eelnõu",
    doc_number: "594 SE IX",
    year: 2003,
    related_act_slug: "ee-kriminaalmenetluse-seadustik",
    title: "Kriminaalmenetluse seadustiku eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/3cbbe022-95f6-32ec-be3c-9c4aa0001f34/kriminaalmenetluse-seadustik",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-208-se-x",
    doc_kind: "eelnõu",
    doc_number: "208 SE X",
    year: 2005,
    related_act_slug: "ee-tsiviilkohtumenetluse-seadustik",
    title: "Tsiviilkohtumenetluse seadustiku eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/4343fca8-f625-3b19-9916-b7c4402ee41d/tsiviilkohtumenetluse-seadustik",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-456-se-ix",
    doc_kind: "eelnõu",
    doc_number: "456 SE IX",
    year: 2001,
    related_act_slug: "ee-haldusmenetluse-seadus",
    title: "Haldusmenetluse seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/b685a9e5-b035-3e9c-8205-90d9ed5eddd0/haldusmenetluse-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-902-se-xi",
    doc_kind: "eelnõu",
    doc_number: "902 SE XI",
    year: 2011,
    related_act_slug: "ee-halduskohtumenetluse-seadustik",
    title: "Halduskohtumenetluse seadustiku eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/997fa4fe-67bd-beab-7916-e6b9747dca8e/halduskohtumenetluse-seadustik",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-116-se-ix",
    doc_kind: "eelnõu",
    doc_number: "116 SE IX",
    year: 2001,
    related_act_slug: "ee-volaoigusseadus",
    title: "Võlaõigusseaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/0d9390ea-974c-35ab-a6c7-cb14062c3ad3/volaoigusseadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-515-se-vii",
    doc_kind: "eelnõu",
    doc_number: "515 SE VII",
    year: 1994,
    related_act_slug: "ee-tsiviilseadustiku-uldosa-seadus",
    title: "Tsiviilseadustiku üldosa seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/b226703a-6b23-31e6-86cd-9c3a6200037a/tsiviilseadustiku-uldosa-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-537-se-xi",
    doc_kind: "eelnõu",
    doc_number: "537 SE XI",
    year: 2009,
    related_act_slug: "ee-valismaalaste-seadus",
    title: "Välismaalaste seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/a9269107-b4ab-c542-3a15-c72dd03d8488/valismaalaste-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-49-se-xi",
    doc_kind: "eelnõu",
    doc_number: "49 SE XI",
    year: 2011,
    related_act_slug: "ee-korrakaitseseadus",
    title: "Korrakaitseseaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/8a9c2286-06fc-65d2-957b-bd9e11a940c4/korrakaitseseadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-299-se-xi",
    doc_kind: "eelnõu",
    doc_number: "299 SE XI",
    year: 2008,
    related_act_slug: "ee-tooleping-seadus",
    title: "Töölepingu seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/92c984a5-95ab-8584-38cd-05fc754e99c4/toolepingu-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-384-se-xi",
    doc_kind: "eelnõu",
    doc_number: "384 SE XI",
    year: 2008,
    related_act_slug: "ee-vordse-kohtlemise-seadus",
    title: "Võrdse kohtlemise seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/cc5e0cc0-2620-3f44-e381-071e238b4195/vordse-kohtlemise-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-pohiseadus-1992",
    doc_kind: "seletuskiri",
    doc_number: "Põhiseaduse Assamblee 1992 seletuskiri",
    year: 1992,
    related_act_slug: "ee-pohiseadus",
    title:
      "Eesti Vabariigi põhiseaduse Assamblee seletuskiri ja eelnõu materjalid",
    // Põhiseadus 1992 predates Riigikogu eelnõude infosüsteem.
    // Best stable proxy: the Riigi Teataja base text of põhiseadus.
    // Will likely fail in Sonnet extraction (no §-keyed seletuskiri exists);
    // we ship it as a placeholder so the row reserves a slot for future
    // manual ingestion of Põhiseaduse Assamblee materjalid.
    url: "https://www.riigiteataja.ee/akt/115052015002",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-37-se-xiii",
    doc_kind: "eelnõu",
    doc_number: "37 SE XIII",
    year: 2015,
    related_act_slug: "ee-tarbijakaitseseadus",
    title: "Tarbijakaitseseaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/523b11ef-443a-421c-ad77-12afca358c06/tarbijakaitseseadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-702-se-xiv",
    doc_kind: "eelnõu",
    doc_number: "702 SE XIV",
    year: 2023,
    related_act_slug: "ee-ohvriabi-seadus",
    title: "Ohvriabi seaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/60f3902f-47aa-43c5-b28f-88101027e454/ohvriabi-seadus",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-55-se-xi",
    doc_kind: "eelnõu",
    doc_number: "55 SE XI",
    year: 2009,
    related_act_slug: "ee-perekonnaseadus",
    title: "Perekonnaseaduse eelnõu",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/982033c7-c2e1-2ce6-0479-ef2bf925488b/perekonnaseadus",
    jurisdiction: "ee",
  },
];

export const ALL_SEEDS: TravauxSeed[] = [...FI_HE_SEEDS, ...EE_EELNOU_SEEDS];
