// calc_rates_test.ts — pure-logic tests for the calc-rates endpoint.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-none supabase/functions/_tests/calc_rates_test.ts
//
// Covers version selection (latest effective_from wins), future-row exclusion,
// jurisdiction validation, and the response envelope shape. No DB / network.
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildResponse,
  type CalcRateRow,
  normaliseJurisdiction,
  RATES_DISCLAIMER,
  selectLatestRates,
} from "../calc-rates/rates.ts";

function row(partial: Partial<CalcRateRow>): CalcRateRow {
  return {
    jurisdiction: "EE",
    rate_key: "child_support_floor",
    value_numeric: null,
    payload: {},
    currency: null,
    effective_from: "2026-01-01",
    source_label: "",
    source_url: "",
    ...partial,
  };
}

Deno.test("normaliseJurisdiction accepts FI/EE case-insensitively", () => {
  assertEquals(normaliseJurisdiction("fi"), "FI");
  assertEquals(normaliseJurisdiction(" EE "), "EE");
});

Deno.test("normaliseJurisdiction rejects unsupported / non-string", () => {
  assertThrows(() => normaliseJurisdiction("DE"), Error, "unsupported");
  assertThrows(() => normaliseJurisdiction(123), Error, "required");
  assertThrows(() => normaliseJurisdiction(undefined), Error, "required");
});

Deno.test("selectLatestRates keeps the newest in-force version per key", () => {
  const rows: CalcRateRow[] = [
    row({
      rate_key: "child_support_floor",
      effective_from: "2024-01-01",
      value_numeric: 180,
    }),
    row({
      rate_key: "child_support_floor",
      effective_from: "2026-01-01",
      value_numeric: 209.2,
    }),
    row({
      rate_key: "state_fee_brackets",
      effective_from: "2025-06-01",
      value_numeric: null,
    }),
  ];
  const out = selectLatestRates(rows, "2026-06-15");
  assertEquals(out["child_support_floor"].value_numeric, 209.2);
  assertEquals(out["child_support_floor"].effective_from, "2026-01-01");
  // distinct key preserved
  assertEquals(out["state_fee_brackets"].effective_from, "2025-06-01");
});

Deno.test("selectLatestRates excludes rows not yet in force", () => {
  const rows: CalcRateRow[] = [
    row({ effective_from: "2026-01-01", value_numeric: 209.2 }),
    row({ effective_from: "2027-01-01", value_numeric: 250 }), // future amendment
  ];
  const out = selectLatestRates(rows, "2026-06-15");
  // future row ignored — current floor stays 209.2
  assertEquals(out["child_support_floor"].value_numeric, 209.2);
});

Deno.test(
  "selectLatestRates returns empty map when nothing in force yet",
  () => {
    const rows: CalcRateRow[] = [
      row({ effective_from: "2030-01-01", value_numeric: 999 }),
    ];
    assertEquals(selectLatestRates(rows, "2026-06-15"), {});
  }
);

Deno.test("buildResponse wraps rates with as_of + disclaimer", () => {
  const rows: CalcRateRow[] = [row({ value_numeric: 209.2 })];
  const resp = buildResponse("EE", rows, "2026-06-15");
  assertEquals(resp.jurisdiction, "EE");
  assertEquals(resp.as_of, "2026-06-15");
  assertEquals(resp.disclaimer, RATES_DISCLAIMER);
  assertEquals(resp.rates["child_support_floor"].value_numeric, 209.2);
});
