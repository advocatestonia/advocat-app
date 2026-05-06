// Deno tests for law-lookup edge function (Phase 2 Pkg 1+2).
//
// Same testing strategy as law_search_test.ts: do NOT boot the full
// serve() handler (would need a live Supabase project), instead static-
// source-test index.ts to lock validation, CORS wiring, and the
// graceful-fail contract that lib/services/law_lookup_client.dart
// depends on.
//
// Run from supabase/functions/law-lookup/ with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land

import {
  assert,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

const indexSrc = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
const indexCode = indexSrc
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("index.ts — wire format matches law_lookup_client.dart", () => {
  // Client posts: { act, paragraph, jurisdiction }. Function MUST read
  // those exact field names.
  for (const field of ["act", "paragraph", "jurisdiction"]) {
    assertStringIncludes(
      indexCode,
      `body.${field}`,
      `index.ts must read body.${field} (client wire shape)`,
    );
  }

  // Client expects `{ statute: {...} | null }` at the top level.
  assertStringIncludes(
    indexCode,
    "statute",
    "index.ts must return a `statute` field (client wire shape)",
  );

  // Per-statute fields the client parses.
  for (
    const field of [
      "act_slug",
      "act_name",
      "paragraph",
      "title",
      "body",
      "source_url",
      "version_date",
      "jurisdiction",
    ]
  ) {
    assertStringIncludes(
      indexCode,
      field,
      `index.ts response must include '${field}'`,
    );
  }
});

Deno.test("index.ts — validates jurisdiction against {EE, FI, EU}", () => {
  assertStringIncludes(indexCode, "SUPPORTED_JURISDICTIONS");
  // Confirm exactly the three supported values are present.
  assert(
    /SUPPORTED_JURISDICTIONS\s*=\s*new Set\(\[\s*"EE"\s*,\s*"FI"\s*,\s*"EU"\s*\]\)/
      .test(indexCode),
    "SUPPORTED_JURISDICTIONS must be exactly {EE, FI, EU}",
  );
  // 400 path on invalid jurisdiction.
  assert(
    /Invalid 'jurisdiction'/.test(indexCode),
    "Function must return 400 on unsupported jurisdiction",
  );
});

Deno.test("index.ts — defaults jurisdiction to 'EE'", () => {
  assert(
    /DEFAULT_JURISDICTION\s*=\s*"EE"/.test(indexCode),
    "default jurisdiction must be EE",
  );
});

Deno.test("index.ts — required fields: act + paragraph", () => {
  assert(
    /Missing or empty 'act'/.test(indexCode),
    "must reject missing 'act' with 400",
  );
  assert(
    /Missing or empty 'paragraph'/.test(indexCode),
    "must reject missing 'paragraph' with 400",
  );
});

Deno.test("index.ts — size guards on act/paragraph lengths", () => {
  assertStringIncludes(indexCode, "MAX_ACT_LEN");
  assertStringIncludes(indexCode, "MAX_PARAGRAPH_LEN");
  // Both have a 4xx path.
  assert(
    /'act' too long/.test(indexCode),
    "must reject oversized 'act' with 400",
  );
  assert(
    /'paragraph' too long/.test(indexCode),
    "must reject oversized 'paragraph' with 400",
  );
});

Deno.test("index.ts — graceful no-op returns 200 + statute:null", () => {
  // The nullStatute helper must exist and produce the wire-shape body.
  assertStringIncludes(indexCode, "nullStatute");
  assert(
    /statute:\s*null/.test(indexCode),
    "graceful no-op must return statute: null",
  );
  // Empty rows path → nullStatute (not 404).
  assert(
    /rows\.length\s*===\s*0[^]*?nullStatute/.test(indexCode),
    "empty RPC result must collapse to nullStatute (graceful contract)",
  );
});

Deno.test("index.ts — uses the shared CORS + auth gate", () => {
  assertStringIncludes(indexCode, '"../_shared/auth.ts"');
  assertStringIncludes(indexCode, "corsHeaders");
  assertStringIncludes(indexCode, "requireUserWithRateLimit");
  // OPTIONS pre-flight returns CORS-only.
  assert(
    /OPTIONS[^]*?corsHeaders/.test(indexCode),
    "OPTIONS pre-flight must return corsHeaders",
  );
});

Deno.test("index.ts — calls lookup_statute RPC with the right param names", () => {
  // The migration grants execute on lookup_statute(text, text, text) with
  // parameter names p_act_slug, p_paragraph, p_jurisdiction. The edge
  // function MUST use those exact names — Postgres won't auto-map.
  assertStringIncludes(indexCode, '"lookup_statute"');
  for (const param of ["p_act_slug", "p_paragraph", "p_jurisdiction"]) {
    assertStringIncludes(
      indexCode,
      param,
      `RPC call must pass '${param}' (matches migration signature)`,
    );
  }
});

Deno.test("index.ts — rate limits match anon-friendly pattern", () => {
  // Lookup is cheap (no embedding, no Anthropic call) so we can afford
  // a more generous anon cap than law-search. 30/min is the chosen value.
  assert(
    /anonymousPerMinute\s*:\s*ANON_RATE_LIMIT_PER_MINUTE/.test(indexCode) ||
      /anonymousPerMinute\s*:\s*\d+/.test(indexCode),
    "anon callers must be allowed (anonymousPerMinute set)",
  );
  assert(
    /ANON_RATE_LIMIT_PER_MINUTE\s*=\s*30/.test(indexCode),
    "anon limit must be 30/min (lookup is cheap)",
  );
});

Deno.test("index.ts — POST-only", () => {
  assert(
    /req\.method\s*!==\s*"POST"/.test(indexCode),
    "non-POST methods must be rejected",
  );
  assertStringIncludes(indexCode, "Method not allowed");
});
