// demand-letter/presets.ts — Feature #2 (Demand-Letter Generator).
// -----------------------------------------------------------------------------
// Static, reference-only data: the four supported demand-letter presets and the
// per-jurisdiction legal-norm citations each one leans on. Kept as pure data
// (no IO) so both the edge function and the unit tests can import it directly.
//
// A "demand letter" (FI: maksuvaatimus / vaatimuskirje, EE: nõudekiri) is a
// pre-court formal demand. We support four narrow, guided presets — NOT a free
// editor — so the output stays a generic informational form, not individual
// legal advice (UPL mitigation: see index.ts disclaimer handling).
//
// Each preset declares:
//   * the user-facing claim type id,
//   * the legal-norm references to surface per jurisdiction (FI / EE), with a
//     short human label, the statute slug used by the citation corpus, and the
//     article. The edge fn passes these slugs to the verifier so a hallucinated
//     citation can never reach the user.
// -----------------------------------------------------------------------------

/** The four supported claim types. */
export type ClaimType =
  | "deposit_return"
  | "unpaid_wage"
  | "fine_dispute"
  | "generic_claim";

export const CLAIM_TYPES: readonly ClaimType[] = [
  "deposit_return",
  "unpaid_wage",
  "fine_dispute",
  "generic_claim",
] as const;

/** ISO-3166 alpha-2 jurisdictions we ship legal references for. */
export type Jurisdiction = "FI" | "EE";

/** A single statutory reference offered for a (claim type, jurisdiction) pair. */
export interface NormRef {
  /** Short human label, e.g. "VÕS § 218" / "TLS § 30". */
  label: string;
  /** Corpus slug used by the citation verifier (e.g. "ee-vos", "fi-tsl"). */
  slug: string;
  /** Article / section, e.g. "218" or "2:9". */
  article: string;
  /** One-line plain-language reason this norm applies. */
  note: string;
}

/** Per-jurisdiction norm references for a claim type. */
type NormsByJurisdiction = Record<Jurisdiction, NormRef[]>;

/**
 * The norm reference table. Conservative, well-established provisions only —
 * we never invent a citation. Empty arrays are valid (generic_claim has no
 * automatic statutory anchor; the user states their own basis).
 */
export const PRESET_NORMS: Record<ClaimType, NormsByJurisdiction> = {
  deposit_return: {
    EE: [
      {
        label: "VÕS § 308",
        slug: "ee-vos",
        article: "308",
        note: "Üürileandja peab tagatisraha tagastama üürisuhte lõppemisel.",
      },
      {
        label: "VÕS § 94",
        slug: "ee-vos",
        article: "94",
        note: "Viivis rahalise kohustuse täitmisega viivitamisel.",
      },
    ],
    FI: [
      {
        label: "AHVL 8 §",
        slug: "fi-ahvl",
        article: "8",
        note: "Vuokravakuus palautetaan, kun vuokrasuhde päättyy ja velvoitteet täytetty.",
      },
      {
        label: "KorkoL 4 §",
        slug: "fi-korkol",
        article: "4",
        note: "Viivästyskorko erääntyneelle rahasaatavalle.",
      },
    ],
  },
  unpaid_wage: {
    EE: [
      {
        label: "TLS § 33",
        slug: "ee-tls",
        article: "33",
        note: "Töötasu makstakse kokkulepitud ajal; lõpparve töösuhte lõppemisel.",
      },
      {
        label: "VÕS § 94",
        slug: "ee-vos",
        article: "94",
        note: "Viivis maksmisega viivitamisel.",
      },
    ],
    FI: [
      {
        label: "TSL 2:13 §",
        slug: "fi-tsl",
        article: "2:13",
        note: "Palkka on maksettava palkanmaksukauden viimeisenä päivänä, ellei toisin sovita.",
      },
      {
        label: "TSL 2:14 §",
        slug: "fi-tsl",
        article: "2:14",
        note: "Työsuhteen päättyessä saatavat erääntyvät; odotusajan palkka viivästyksestä.",
      },
    ],
  },
  fine_dispute: {
    EE: [
      {
        label: "HMS § 75",
        slug: "ee-hms",
        article: "75",
        note: "Vaie haldusakti peale esitatakse 30 päeva jooksul teatavaks tegemisest.",
      },
    ],
    FI: [
      {
        label: "HL 49 b §",
        slug: "fi-hl",
        article: "49b",
        note: "Oikaisuvaatimus tehdään 30 päivän kuluessa päätöksen tiedoksisaannista.",
      },
    ],
  },
  generic_claim: {
    EE: [
      {
        label: "VÕS § 76",
        slug: "ee-vos",
        article: "76",
        note: "Kohustus tuleb täita vastavalt lepingule ja seadusele.",
      },
    ],
    FI: [
      {
        label: "VelkakirjaL 5 §",
        slug: "fi-velkakirjal",
        article: "5",
        note: "Velka on maksettava vaadittaessa, ellei eräpäivästä ole sovittu.",
      },
    ],
  },
};

/** Returns the norm references for a claim type + jurisdiction (never null). */
export function normsFor(
  claim: ClaimType,
  jurisdiction: Jurisdiction
): NormRef[] {
  const byJur = PRESET_NORMS[claim];
  if (!byJur) return [];
  return byJur[jurisdiction] ?? [];
}

/** True when [v] is one of the four supported claim types. */
export function isClaimType(v: unknown): v is ClaimType {
  return (
    typeof v === "string" && (CLAIM_TYPES as readonly string[]).includes(v)
  );
}

/** True when [v] is a jurisdiction we have norms for. */
export function isJurisdiction(v: unknown): v is Jurisdiction {
  return v === "FI" || v === "EE";
}
