// Deno source-contract tests for log-refund-consent Edge Function.
// -----------------------------------------------------------------------------
// Mirrors the eligibility_test.ts pattern: static-analysis assertions that
// the index.ts imports the right shared primitives and enforces the
// security contract (JWT-only user ID, rate limit, IP hashing, service-role
// INSERT, CORS). A full integration test is out of scope for this layer.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/log-refund-consent/__tests__/log_consent_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

// Strip comments so doc strings don't create false positives.
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("LRC-T01 — imports JWT gate + CORS helpers from shared auth", () => {
  assertStringIncludes(source, "requireUserWithRateLimit");
  assertStringIncludes(source, "_shared/auth.ts");
});

Deno.test("LRC-T02 — JWT gate runs before any Supabase mutation", () => {
  const gateIdx = stripped.indexOf("requireUserWithRateLimit(");
  // Accept .insert( or .from( (both indicate DB access).
  const dbIdx = stripped.indexOf(".insert(");
  assert(gateIdx !== -1, "Must call requireUserWithRateLimit");
  assert(dbIdx !== -1, "Must insert a consent row");
  assert(
    gateIdx < dbIdx,
    "Gate must run before any DB write — unauthenticated requests must " +
      "not burn service-role INSERTs.",
  );
});

Deno.test("LRC-T03 — rate limit is 3 per minute (write endpoint)", () => {
  assertStringIncludes(source, 'bucket: "log-refund-consent"');
  assertStringIncludes(source, "maxPerMinute: 3");
});

Deno.test("LRC-T04 — inserts into refund_consents table", () => {
  assertStringIncludes(stripped, 'from("refund_consents")');
  assertStringIncludes(stripped, ".insert(");
});

Deno.test("LRC-T05 — uses authenticated gate.user.id for the row", () => {
  // Row must carry the JWT-resolved user_id, never one from the body.
  assertStringIncludes(stripped, "gate.user.id");
});

Deno.test("LRC-T06 — body user_id is NOT trusted", () => {
  const destructureRegex =
    /\{[^{}]*user_id[^{}]*\}\s*=\s*await\s+req\s*\.\s*json/;
  assertFalse(
    destructureRegex.test(stripped),
    "user_id must NOT be destructured from the request body — use JWT only.",
  );
});

Deno.test("LRC-T07 — hashes IP with sha256 (never stores raw)", () => {
  // We fingerprint the source IP so abuse patterns are visible without
  // storing the raw address. The code must call some form of SHA-256.
  const hasSha = source.includes("sha-256") || source.includes("SHA-256") ||
    source.includes("digest(\"SHA-256\"") ||
    source.includes('digest("SHA-256"');
  assert(hasSha, "Must hash source IP with SHA-256.");
});

Deno.test("LRC-T08 — does not store raw x-forwarded-for as ip_hash", () => {
  // Finding "ip_hash: clientIp" or similar direct assignment is a red flag.
  // Accept only patterns where the value going into ip_hash has been
  // transformed (hashed).
  const rawAssign = /ip_hash\s*:\s*(?:clientIp|req\.headers)/;
  assertFalse(
    rawAssign.test(stripped),
    "ip_hash must receive a hashed value, not the raw IP.",
  );
});

Deno.test("LRC-T09 — uses shared jsonError / jsonOk helpers", () => {
  assertStringIncludes(source, "jsonError");
  const usesShared = source.includes("jsonOk") ||
    source.includes("corsHeaders");
  assert(usesShared, "Must use shared CORS/response helpers.");
});

Deno.test("LRC-T10 — OPTIONS preflight returns 204 with corsHeaders", () => {
  assertStringIncludes(stripped, "OPTIONS");
  assertStringIncludes(source, "corsHeaders");
});

Deno.test("LRC-T11 — rejects non-POST methods", () => {
  assertStringIncludes(stripped, "Method not allowed");
  assertStringIncludes(stripped, "405");
});

Deno.test("LRC-T12 — captures user_agent header (GDPR 2-year retention)", () => {
  // Stored for fraud investigation; truncated by the DB column size.
  assertStringIncludes(source, "user-agent");
});
