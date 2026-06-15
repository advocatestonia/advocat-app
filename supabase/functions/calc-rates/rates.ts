// calc-rates/rates.ts — pure selection + shaping logic for the rates endpoint.
// -----------------------------------------------------------------------------
// Kept side-effect-free (no network, no Deno globals) so it is unit-testable in
// isolation. The `index.ts` handler does the DB read and CORS/auth; this module
// only validates input and picks the latest-effective version per rate_key.
// -----------------------------------------------------------------------------

/** A single row as stored in public.calc_rates. */
export interface CalcRateRow {
  jurisdiction: string;
  rate_key: string;
  value_numeric: number | null;
  payload: Record<string, unknown>;
  currency: string | null;
  effective_from: string; // ISO date 'YYYY-MM-DD'
  source_label: string;
  source_url: string;
}

/** Shaped rate returned to the client. */
export interface CalcRate {
  rate_key: string;
  value_numeric: number | null;
  payload: Record<string, unknown>;
  currency: string | null;
  effective_from: string;
  source_label: string;
  source_url: string;
}

export interface RatesResponse {
  jurisdiction: string;
  as_of: string;
  rates: Record<string, CalcRate>;
  /** Indicative-only marker the UI surfaces verbatim. */
  disclaimer: string;
}

export const SUPPORTED_JURISDICTIONS = ["FI", "EE"] as const;
export type SupportedJurisdiction = (typeof SUPPORTED_JURISDICTIONS)[number];

export const RATES_DISCLAIMER =
  "Indicative figures from published statutory sources. Not an official " +
  "calculation or legal advice. Verify the current rate at the cited source.";

/** Normalise + validate a requested jurisdiction. Throws on unsupported. */
export function normaliseJurisdiction(input: unknown): SupportedJurisdiction {
  if (typeof input !== "string") {
    throw new Error("jurisdiction required");
  }
  const up = input.trim().toUpperCase();
  if ((SUPPORTED_JURISDICTIONS as readonly string[]).includes(up)) {
    return up as SupportedJurisdiction;
  }
  throw new Error(`unsupported jurisdiction: ${input}`);
}

/**
 * From all rows for a jurisdiction, keep only the latest row per rate_key whose
 * `effective_from` is on or before `asOf`. Returns a keyed map.
 *
 * `asOf` defaults to today (UTC). Rows with a future effective_from are ignored
 * so a pre-loaded future amendment never leaks early.
 */
export function selectLatestRates(
  rows: CalcRateRow[],
  asOf: string = isoToday()
): Record<string, CalcRate> {
  const out: Record<string, CalcRate> = {};
  for (const row of rows) {
    if (row.effective_from > asOf) continue; // not yet in force
    const existing = out[row.rate_key];
    if (!existing || row.effective_from > existing.effective_from) {
      out[row.rate_key] = {
        rate_key: row.rate_key,
        value_numeric: row.value_numeric,
        payload: row.payload ?? {},
        currency: row.currency,
        effective_from: row.effective_from,
        source_label: row.source_label,
        source_url: row.source_url,
      };
    }
  }
  return out;
}

/** Build the full response envelope. */
export function buildResponse(
  jurisdiction: SupportedJurisdiction,
  rows: CalcRateRow[],
  asOf: string = isoToday()
): RatesResponse {
  const rates = selectLatestRates(rows, asOf);
  return {
    jurisdiction,
    as_of: asOf,
    rates,
    disclaimer: RATES_DISCLAIMER,
  };
}

/** Current UTC date as 'YYYY-MM-DD'. */
export function isoToday(): string {
  return new Date().toISOString().slice(0, 10);
}
