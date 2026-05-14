// Deno tests for hudoc-fetcher/fetcher.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the normaliser + itemid validation. Live HUDOC
// fetches are not exercised in the unit suite; use a manual smoke run
// after deploy.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { fetchHudocDoc, HudocFetchError, normaliseHit } from "../fetcher.ts";

// =============================================================================
// normaliseHit — both response shapes
// =============================================================================

Deno.test("HU-F01 — normaliseHit accepts {columns: {...}} shape", () => {
  const hit = normaliseHit({
    columns: {
      itemid: "001-157670",
      appno: "23380/09",
      docname: "CASE OF BOUYID v. BELGIUM",
      judgement_date: "2015-09-28T00:00:00Z",
      importance: 1,
      respondent: "Belgium",
    },
  });
  assert(hit);
  assertEquals(hit.itemid, "001-157670");
  assertEquals(hit.appno, "23380/09");
  assertEquals(hit.importance, 1);
});

Deno.test("HU-F02 — normaliseHit accepts flat shape", () => {
  const hit = normaliseHit({
    itemid: "001-89046",
    appno: "1638/03",
    docname: "MASLOV v. AUSTRIA",
    importance: "1",
  });
  assert(hit);
  assertEquals(hit.itemid, "001-89046");
  assertEquals(hit.importance, 1);  // coerced from string
});

Deno.test("HU-F05 — normaliseHit prefers kpdate over judgement_date", () => {
  const hit = normaliseHit({
    columns: {
      itemid: "001-157670",
      appno: "23380/09",
      docname: "CASE OF BOUYID v. BELGIUM",
      kpdate: "2015-09-28T00:00:00",
      doctypebranch: "GRANDCHAMBER",
      languageisocode: "ENG",
      importance: "1",
    },
  });
  assert(hit);
  assertEquals(hit.judgement_date, "2015-09-28T00:00:00");
  assertEquals(hit.doctypebranch, "GRANDCHAMBER");
  assertEquals(hit.languageisocode, "ENG");
});

Deno.test("HU-F06 — normaliseHit falls back to judgement_date when kpdate absent", () => {
  const hit = normaliseHit({
    columns: {
      itemid: "001-87156",
      appno: "1638/03",
      docname: "CASE OF MASLOV v. AUSTRIA",
      judgement_date: "2008-06-23T00:00:00Z",
      importance: 1,
    },
  });
  assert(hit);
  assertEquals(hit.judgement_date, "2008-06-23T00:00:00Z");
});

Deno.test("HU-F03 — normaliseHit returns null on missing itemid", () => {
  assertEquals(normaliseHit({ columns: { appno: "1/02" } }), null);
  assertEquals(normaliseHit({ itemid: "" }), null);
  assertEquals(normaliseHit({}), null);
  assertEquals(normaliseHit(null), null);
});

Deno.test("HU-F04 — normaliseHit returns null for non-object input", () => {
  assertEquals(normaliseHit("string"), null);
  assertEquals(normaliseHit(42), null);
});

// =============================================================================
// fetchHudocDoc itemid validation
// =============================================================================

Deno.test("HU-F10 — fetchHudocDoc rejects malformed itemid", async () => {
  await assertRejects(
    () => fetchHudocDoc("not-an-itemid"),
    HudocFetchError,
    "Invalid HUDOC itemid",
  );
  await assertRejects(
    () => fetchHudocDoc("001-"),
    HudocFetchError,
  );
  await assertRejects(
    () => fetchHudocDoc("002-12345"),  // wrong prefix
    HudocFetchError,
  );
});

Deno.test("HU-F11 — fetchHudocDoc accepts well-formed itemid (network-deferred)", () => {
  // We pre-abort so the function exits before any real network. The point
  // here is purely that the regex gate does NOT reject this id.
  const ctrl = new AbortController();
  ctrl.abort("test");
  return fetchHudocDoc("001-157670", { signal: ctrl.signal })
    .then(() => {
      throw new Error("should have rejected, not resolved");
    })
    .catch((e) => {
      // The error should NOT mention "Invalid HUDOC itemid format".
      const msg = String(e);
      assert(!msg.includes("Invalid HUDOC itemid"));
    });
});
