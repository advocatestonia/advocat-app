// statutory_anchors.ts — Phase 2 Pkg 9 deadline radar.
// -----------------------------------------------------------------------------
// Registry of statutory deadline templates. The extractor matches on
// `(jurisdiction, triggerDocTypes)` to apply a template; modifiers are
// composable additions to the service-clock (e.g. HMS §27 +5d).
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §2.
//
// Pure module — testable without Supabase env. No Deno globals.
// -----------------------------------------------------------------------------

import type {
  DeadlineJurisdiction,
  ShiftPolicy,
  StatutoryUnit,
} from "./holiday_shift.ts";

/** Localized UI labels (ET / FI / EN / RU). EN is required, others optional. */
export interface StatutoryAnchorLabels {
  en: string;
  et?: string;
  fi?: string;
  ru?: string;
}

/** A deadline template — applied by the extractor when a matching trigger
 * document is identified. Modifiers are not deadlines on their own; they
 * adjust the service-clock of a base deadline. */
export interface StatutoryAnchor {
  /** Unique key, also used as the FK identifier in `case_deadlines.anchor_key`. */
  key: string;
  /** Jurisdiction code. EU = ECHR Strasbourg only. */
  jurisdiction: DeadlineJurisdiction;
  /** Citing statute ("HKMS §46", "HOL §164", "ECHR Protocol 15"). */
  statute: string;
  /** Whether this template represents an actionable deadline or just a
   * service-clock modifier. */
  kind: "deadline" | "modifier";
  /** Magnitude of the time window. */
  days: number;
  /** Unit for `days`. */
  unit: StatutoryUnit;
  /** What kinds of upstream documents trigger this template. Required for
   * `kind='deadline'`; modifiers may omit this (handled by the extractor's
   * service-clock logic). */
  triggerDocTypes?: readonly string[];
  /** Holiday-shift policy. ECHR Protocol 15 is `strict_calendar`; everything
   * else defaults to `next_business_day`. */
  holidayShiftPolicy: ShiftPolicy;
  /** Human-readable explanation of the service basis. Surfaced in the UI
   * tooltip ("HL §60 turvaviesti — 7th calendar day from sending"). */
  serviceBasis: string;
  /** Optional localized UI labels. Required for `kind='deadline'`. */
  uiLabels?: StatutoryAnchorLabels;
  /** Optional default priority for case_deadlines.priority. */
  defaultPriority?: "critical" | "high" | "medium" | "low";
}

/** The single registry. Extending: add a new entry here AND mirror it in
 * the Postgres `pg_compute_deadline` SQL function (see migration
 * 20260507_12_deadline_extractor_rpcs.sql). */
export const STATUTORY_DEADLINE_TEMPLATES: Readonly<
  Record<string, StatutoryAnchor>
> = {
  // ── EE — Estonian admin proceedings ─────────────────────────────────
  ee_hkms_46_kaebus: {
    key: "ee_hkms_46_kaebus",
    jurisdiction: "EE",
    statute: "HKMS §46",
    kind: "deadline",
    days: 30,
    unit: "calendar_days",
    triggerDocTypes: ["court_decision", "haldusotsus"],
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HKMS §46 — kaebus halduskohtule 30 kalendripäeva jooksul " +
      "haldusotsuse kättesaamisest",
    defaultPriority: "critical",
    uiLabels: {
      en: "Appeal to Administrative Court",
      et: "Kaebus halduskohtule",
      ru: "Жалоба в адм. суд",
    },
  },

  ee_hms_75_vaie: {
    key: "ee_hms_75_vaie",
    jurisdiction: "EE",
    statute: "HMS §75",
    kind: "deadline",
    days: 30,
    unit: "calendar_days",
    triggerDocTypes: ["admin_decision"],
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HMS §75 — vaie haldusorganile 30 kalendripäeva jooksul",
    defaultPriority: "critical",
    uiLabels: {
      en: "Administrative complaint",
      et: "Vaie",
      ru: "Возражение",
    },
  },

  ee_hms_27_e_service: {
    key: "ee_hms_27_e_service",
    jurisdiction: "EE",
    statute: "HMS §27",
    kind: "modifier",
    days: 5,
    unit: "calendar_days",
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HMS §27 — elektrooniliselt edastatud dokument loetakse kättesaaduks " +
      "5. kalendripäeval saatmisest",
  },

  // ── FI — Finnish admin / court proceedings ──────────────────────────
  fi_hol_2019_808_khoa: {
    key: "fi_hol_2019_808_khoa",
    jurisdiction: "FI",
    statute: "Hallintolainkäyttölaki + HOL §164",
    kind: "deadline",
    days: 30,
    unit: "calendar_days",
    triggerDocTypes: ["court_decision", "khoa_paatos", "hao_paatos"],
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HOL §164 — valitus KHO:hon 30 kalendripäivän kuluessa päätöksen " +
      "tiedoksisaannista (HL §59/§60 service-clock)",
    defaultPriority: "critical",
    uiLabels: {
      en: "Appeal to Supreme Admin Court",
      fi: "Valitus KHO:hon",
      ru: "Апелляция KHO",
    },
  },

  fi_hl_49b_oikaisu: {
    key: "fi_hl_49b_oikaisu",
    jurisdiction: "FI",
    statute: "Hallintolaki §49b",
    kind: "deadline",
    days: 30,
    unit: "calendar_days",
    triggerDocTypes: ["admin_decision"],
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HL §49b — oikaisuvaatimus 30 päivän kuluessa päätöksen tiedoksisaannista",
    defaultPriority: "critical",
    uiLabels: {
      en: "Administrative reclamation",
      fi: "Oikaisuvaatimus",
      ru: "Заявление об исправлении",
    },
  },

  fi_hl_59_regular_email_service: {
    key: "fi_hl_59_regular_email_service",
    jurisdiction: "FI",
    statute: "HL §59",
    kind: "modifier",
    days: 3,
    unit: "working_days",
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HL §59 — tavanomainen sähköpostitiedoksianto: tiedoksisaanti " +
      "3 työpäivän kuluttua lähettämisestä",
  },

  fi_hl_60_turvaviesti_service: {
    key: "fi_hl_60_turvaviesti_service",
    jurisdiction: "FI",
    statute: "HL §60",
    kind: "modifier",
    days: 7,
    unit: "calendar_days",
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "HL §60 — turvaviesti / suojattu sähköposti: tiedoksisaanti 7. " +
      "kalenteripäivänä lähettämisestä",
  },

  fi_posti_omniva_pickup: {
    key: "fi_posti_omniva_pickup",
    jurisdiction: "FI",
    statute: "Posti / Omniva",
    kind: "modifier",
    days: 14,
    unit: "calendar_days",
    holidayShiftPolicy: "next_business_day",
    serviceBasis:
      "Posti / Omniva pickup window — physical service: 14 calendar days " +
      "warehouse pickup",
  },

  // ── EU — ECHR Strasbourg ────────────────────────────────────────────
  eu_echr_protocol_15: {
    key: "eu_echr_protocol_15",
    jurisdiction: "EU",
    statute: "ECHR Protocol 15",
    kind: "deadline",
    days: 4,
    unit: "calendar_months",
    triggerDocTypes: ["final_domestic_judgment"],
    // CRITICAL: ECHR does NOT extend over weekends or holidays.
    holidayShiftPolicy: "strict_calendar",
    serviceBasis:
      "ECHR Protocol 15 — application to Strasbourg within 4 calendar " +
      "months of the final domestic judgment; strict calendar, no weekend " +
      "or holiday extension",
    defaultPriority: "critical",
    uiLabels: {
      en: "ECHR application",
      ru: "Жалоба в ЕСПЧ",
    },
  },
};

/** Lookup an anchor by its key. Returns null if unknown. */
export function findAnchor(key: string): StatutoryAnchor | null {
  return STATUTORY_DEADLINE_TEMPLATES[key] ?? null;
}

/** All deadline-kind anchors that match the given jurisdiction + doc type. */
export function findAnchorsByTrigger(
  jurisdiction: DeadlineJurisdiction,
  docType: string,
): StatutoryAnchor[] {
  const out: StatutoryAnchor[] = [];
  for (const a of Object.values(STATUTORY_DEADLINE_TEMPLATES)) {
    if (a.kind !== "deadline") continue;
    if (a.jurisdiction !== jurisdiction) continue;
    if (!a.triggerDocTypes) continue;
    if (a.triggerDocTypes.includes(docType)) {
      out.push(a);
    }
  }
  return out;
}

/** All known anchor keys, for SQL CHECK / TS narrowing. */
export const STATUTORY_ANCHOR_KEYS: readonly string[] = Object.freeze(
  Object.keys(STATUTORY_DEADLINE_TEMPLATES),
);
