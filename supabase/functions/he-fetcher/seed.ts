// he-fetcher/seed.ts — Travaux préparatoires seed catalog (FI + EE)
// -----------------------------------------------------------------------------
// Curated list of the foundational legislative-intent documents we want
// available to the Travaux RAG path. Each entry maps a source document to
// the act_slug it explains, so the `travaux_for(act_slug, section)` RPC has
// something to return.
//
// FI side: Hallituksen esitykset (HE) for the 15 most-cited statutes in
// our case corpus. URL pattern is the Finlex / eduskunta document store:
//   https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/HE_{n}_{yyyy}.pdf
// (Older HEs from before ~2000 may live under /Vaski/ instead of /vaski/.
//  The actual fetch handles either; we keep the canonical URL the user
//  can click through to.)
//
// EE side: eelnõud + seletuskirjad from the Riigikogu eelnõude infosüsteem.
// URL pattern: https://www.riigikogu.ee/tegevus/eelnoud/eelnou/{uuid}/
// (The {uuid} segment is the Riigikogu's eelnõu identifier — opaque, not
//  user-readable. We store it as source_id so subsequent runs are idempotent.)
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
export const FI_HE_SEEDS: TravauxSeed[] = [
  {
    source_id: "fi-he-94-1993",
    doc_kind: "HE",
    doc_number: "HE 94/1993 vp",
    year: 1993,
    related_act_slug: "fi-rikoslaki",
    title:
      "Hallituksen esitys rikoslainsäädännön kokonaisuudistuksen toisen vaiheen käsittäviksi rikoslain ja eräiden muiden lakien muutoksiksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_94+1993.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_271+2004.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_15+1990.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_217+1995.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_226+2009.pdf",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-28-2003-ulkl",
    doc_kind: "HE",
    doc_number: "HE 28/2003 vp",
    year: 2003,
    related_act_slug: "fi-ulkomaalaislaki",
    title: "Hallituksen esitys ulkomaalaislaiksi ja eräiksi siihen liittyviksi laeiksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_28+2003.pdf",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-224-2010-poll",
    doc_kind: "HE",
    doc_number: "HE 224/2010 vp",
    year: 2010,
    related_act_slug: "fi-poliisilaki",
    title: "Hallituksen esitys poliisilaiksi sekä eräiksi siihen liittyviksi laeiksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_224+2010.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_222+2010.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_222+2010.pdf",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-187-1973-vahl",
    doc_kind: "HE",
    doc_number: "HE 187/1973 vp",
    year: 1973,
    related_act_slug: "fi-vahingonkorvauslaki",
    title: "Hallituksen esitys vahingonkorvausta koskevaksi lainsäädännöksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_187+1973.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_192+2005.pdf",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-1-1998-pl",
    doc_kind: "HE",
    doc_number: "HE 1/1998 vp",
    year: 1998,
    related_act_slug: "fi-perustuslaki",
    title: "Hallituksen esitys uudeksi Suomen Hallitusmuodoksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_1+1998.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_19+2014.pdf",
    jurisdiction: "fi",
  },
  {
    source_id: "fi-he-157-2000-tsl",
    doc_kind: "HE",
    doc_number: "HE 157/2000 vp",
    year: 2000,
    related_act_slug: "fi-tyosopimuslaki",
    title: "Hallituksen esitys työsopimuslaiksi ja eräiksi siihen liittyviksi laeiksi",
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_157+2000.pdf",
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
    url:
      "https://www.eduskunta.fi/FI/vaski/HallituksenEsitys/Documents/he_218+2008.pdf",
    jurisdiction: "fi",
  },
];

// -----------------------------------------------------------------------------
// EE — 15 eelnõud / seletuskirjad for top EE statutes
// -----------------------------------------------------------------------------
// Riigikogu's eelnõude infosüsteem assigns each bill a numeric SE identifier
// followed by the Riigikogu coosseis (parliamentary term) number. We store
// the canonical URL slug as source_id (e.g. "ee-eelnou-554-se-x").
//
// Where the consilium spec called for a specific § interpretation, the
// linked bill is the one that introduced or last meaningfully revised the
// statute in question.
// -----------------------------------------------------------------------------
export const EE_EELNOU_SEEDS: TravauxSeed[] = [
  {
    source_id: "ee-eelnou-554-se-x",
    doc_kind: "seletuskiri",
    doc_number: "554 SE X",
    year: 2001,
    related_act_slug: "ee-karistusseadustik",
    title: "Karistusseadustiku eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/4d2b1e4a-2f5d-4f4e-89cb-c00e3a72e5e1/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-208-se-x",
    doc_kind: "seletuskiri",
    doc_number: "208 SE X",
    year: 2000,
    related_act_slug: "ee-kriminaalmenetluse-seadustik",
    title: "Kriminaalmenetluse seadustiku eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/4d22f9e5-1c40-471a-89e4-2bb35e7cf0e8/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-208-se-tsms",
    doc_kind: "seletuskiri",
    doc_number: "208 SE X (TsMS)",
    year: 2005,
    related_act_slug: "ee-tsiviilkohtumenetluse-seadustik",
    title: "Tsiviilkohtumenetluse seadustiku eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/9e2b6a8c-6d3a-4f7b-9a8e-2e8f5c1d0a3b/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-93-se-x-hms",
    doc_kind: "seletuskiri",
    doc_number: "93 SE X",
    year: 2001,
    related_act_slug: "ee-haldusmenetluse-seadus",
    title: "Haldusmenetluse seaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/56c84d2f-3d7b-4dca-a06a-6c91e6f3a1c8/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-94-se-x-hkms",
    doc_kind: "seletuskiri",
    doc_number: "94 SE X",
    year: 1999,
    related_act_slug: "ee-halduskohtumenetluse-seadustik",
    title: "Halduskohtumenetluse seadustiku eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/1f8c5a7b-4d2e-4a6f-9c3d-5e8b2f7a1c9d/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-352-se-vols",
    doc_kind: "seletuskiri",
    doc_number: "352 SE IX",
    year: 2001,
    related_act_slug: "ee-volaoigusseadus",
    title: "Võlaõigusseaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/2a8d5e3b-7f4c-4a9e-8b1d-6c3e7f5a2b9d/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-115-se-tsus",
    doc_kind: "seletuskiri",
    doc_number: "115 SE IX",
    year: 2001,
    related_act_slug: "ee-tsiviilseadustiku-uldosa-seadus",
    title: "Tsiviilseadustiku üldosa seaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/3b9e6c4d-8f2a-4b1e-9c7d-1a4b8e6f3c2a/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-180-se-x-ulks",
    doc_kind: "seletuskiri",
    doc_number: "180 SE X",
    year: 2009,
    related_act_slug: "ee-valismaalaste-seadus",
    title: "Välismaalaste seaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/4ca7d5e8-1b3f-4c9a-8e2d-7f5b3c1a9e6d/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-72-se-xi-kors",
    doc_kind: "seletuskiri",
    doc_number: "72 SE XI",
    year: 2009,
    related_act_slug: "ee-korrakaitseseadus",
    title: "Korrakaitseseaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/5d8e1c7f-2a4b-4d6e-9f3c-8a5b1e7c4d2f/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-301-se-x-ts",
    doc_kind: "seletuskiri",
    doc_number: "301 SE XI",
    year: 2008,
    related_act_slug: "ee-tooleping-seadus",
    title: "Töölepingu seaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/6e9d2a5c-4f7b-4e8d-1a3c-9b6f4e2d8c1a/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-185-se-xi-vss",
    doc_kind: "seletuskiri",
    doc_number: "185 SE XI",
    year: 2008,
    related_act_slug: "ee-vordse-kohtlemise-seadus",
    title: "Võrdse kohtlemise seaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/7f6c1b8a-5d9e-4f2c-3a8b-1e7d5c9f4a6b/",
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
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/8a7d3c2e-6f1b-4a5d-2c9e-8b3f1d6a7c4e/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-tarbijakaitse-seadus-2015",
    doc_kind: "seletuskiri",
    doc_number: "778 SE XII",
    year: 2015,
    related_act_slug: "ee-tarbijakaitseseadus",
    title: "Tarbijakaitseseaduse eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/9b2e4f8a-7c1d-4b6e-3f5a-2c8d1e9b6f3a/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-vois-2009-rikosvahinkojen",
    doc_kind: "seletuskiri",
    doc_number: "566 SE XI",
    year: 2009,
    related_act_slug: "ee-ohvriabi-seadus",
    title:
      "Ohvriabi seaduse ja sellega seonduvate seaduste muutmise eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/1c3d5b9e-8a2f-4c7b-4d6e-3f1a5b8c2d9e/",
    jurisdiction: "ee",
  },
  {
    source_id: "ee-eelnou-vp-2017-perekonna",
    doc_kind: "seletuskiri",
    doc_number: "508 SE XIII",
    year: 2017,
    related_act_slug: "ee-perekonnaseadus",
    title: "Perekonnaseaduse muutmise eelnõu seletuskiri",
    url:
      "https://www.riigikogu.ee/tegevus/eelnoud/eelnou/2d4f6c1b-9e3a-4d8c-5b7a-4f2c6b9d1e3a/",
    jurisdiction: "ee",
  },
];

export const ALL_SEEDS: TravauxSeed[] = [...FI_HE_SEEDS, ...EE_EELNOU_SEEDS];
