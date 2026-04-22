// Deno source-contract tests for join-waitlist Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/join-waitlist/__tests__/waitlist_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("JWL-T01 — anonymous-friendly: anonymousPerMinute is set", () => {
  // Waitlist is explicitly for pre-signup visitors, so the gate must
  // allow anonymous traffic under a tight IP-based quota.
  assertStringIncludes(source, "anonymousPerMinute");
  assert(
    /anonymousPerMinute\s*:\s*[1-5](\D|$)/.test(stripped),
    "Anonymous rate limit should be tight (1-5/min)",
  );
});

Deno.test("JWL-T02 — uses shared JWT gate (not hand-rolled)", () => {
  assertStringIncludes(source, "requireUserWithRateLimit");
  assertStringIncludes(source, "_shared/auth.ts");
});

Deno.test("JWL-T03 — inserts into waitlist table", () => {
  assertStringIncludes(stripped, 'from("waitlist")');
  assertStringIncludes(stripped, ".insert(");
});

Deno.test("JWL-T04 — validates email format (rejects obvious garbage)", () => {
  // Must parse the email and return 400 for bad input, never write garbage.
  assertStringIncludes(source, "Invalid email");
  // Regex must exist somewhere.
  assert(
    /\/\^.*@.*\$\//.test(source) || /EMAIL_RE/.test(source),
    "Must have a regex or validator for email format",
  );
});

Deno.test("JWL-T05 — normalises email to lowercase + trim", () => {
  // Otherwise user@example.com and USER@example.com would create two rows.
  assertStringIncludes(stripped, ".toLowerCase()");
  assertStringIncludes(stripped, ".trim()");
});

Deno.test("JWL-T06 — idempotent: duplicate email is 200, not 500", () => {
  // The UX disaster is a user who already joined being told "server error".
  // We must handle unique_violation (23505) gracefully.
  assertStringIncludes(stripped, "already_joined");
  assertStringIncludes(stripped, "23505");
});

Deno.test("JWL-T07 — source param is length-capped to prevent abuse", () => {
  // "source" is free-form ("landing", "beta_cap_full", ...) but we must
  // refuse long payloads that could be used to stuff garbage into logs
  // or blow up row sizes.
  assert(
    /source.*length\s*<=?\s*\d+/.test(stripped) ||
      /\.length\s*<=?\s*64/.test(stripped),
    "source field must have a length cap",
  );
});

Deno.test("JWL-T08 — returns position for new joins", () => {
  // Nice-to-have: shows the user "you're #N on the list" for social proof.
  assertStringIncludes(stripped, "position");
  assertStringIncludes(stripped, "count");
});

Deno.test("JWL-T09 — OPTIONS preflight returns 204 with corsHeaders", () => {
  assertStringIncludes(stripped, "OPTIONS");
  assertStringIncludes(source, "corsHeaders");
});

Deno.test("JWL-T10 — rejects non-POST methods", () => {
  assertStringIncludes(stripped, "Method not allowed");
  assertStringIncludes(stripped, "405");
});

Deno.test("JWL-T11 — does not return a position on repeat joins (privacy)", () => {
  // Disclosing the list length via a repeat join would leak how many
  // waitlisters we have to anyone who guesses an existing email.
  // Look for a repeat-join branch that returns position: null.
  assert(
    /already_joined:\s*true[^}]*position:\s*null/s.test(stripped) ||
      /position:\s*null[^}]*already_joined:\s*true/s.test(stripped),
    "Repeat-join response must NOT disclose position",
  );
});

Deno.test("JWL-T12 — error log truncated (no PII leak)", () => {
  assertStringIncludes(stripped, "message.slice(0, 200)");
});

Deno.test("JWL-T13 — body source is NOT trusted as email", () => {
  // Defence in depth: the email must come from the validated `email`
  // variable, never directly from body.email after validation bypass.
  const destructureRegex =
    /\{[^{}]*email\s*,\s*email[^{}]*\}\s*=\s*await\s+req\s*\.\s*json/;
  assertFalse(
    destructureRegex.test(stripped),
    "email must only be taken from the validated local, never re-read",
  );
});
