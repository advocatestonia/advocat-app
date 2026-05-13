// Source-contract tests for intro_type handling in stripe-webhook.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/stripe-webhook/__tests__/intro_type_recording_test.ts
//
// History: the Early Access founder program was retired (commit removing
// FOUNDER_INTRO_TYPE / cap probe). The `subscriptions.intro_type` column is
// preserved on the schema for the grandfathered founder rows that signed up
// before retirement, and the webhook still forwards any `metadata.intro_type`
// value verbatim — that lets a manual back-fill (e.g. admin tooling) re-stamp
// a historical row without code changes. New launch-pricing checkouts never
// set the metadata field, so introType resolves to null for all new users.
// -----------------------------------------------------------------------------

import {
  assert,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("IT-T01 — webhook still reads metadata.intro_type from session", () => {
  // Kept for historical back-fill: an admin can stamp metadata.intro_type
  // on a manually-created Stripe session and the webhook will forward it.
  assertStringIncludes(stripped, "metadata.intro_type");
});

Deno.test("IT-T02 — subscriptions upsert still writes intro_type", () => {
  // Column preserved on schema. Forwarded verbatim (null for new flows).
  assertStringIncludes(stripped, "intro_type: introType");
});

Deno.test("IT-T03 — founder cap race guard is REMOVED", () => {
  // The retired program had a race-recheck loop that queried subscriptions
  // by intro_type='early-access-100'. Pin its removal so a regression cannot
  // silently re-introduce a 100-seat cap on new launch-pricing checkouts.
  assert(
    !/founder cap recheck/.test(stripped),
    "founder cap race guard must be removed (program retired)",
  );
  assert(
    !/founder slot lost in race/.test(stripped),
    "founder race-loss branch must be removed (program retired)",
  );
  assert(
    !/FOUNDER_TOTAL\s*=/.test(stripped),
    "FOUNDER_TOTAL constant must be removed",
  );
});

Deno.test("IT-T04 — webhook does not query 'early-access-100' (retired flow)", () => {
  assert(
    !/"early-access-100"/.test(stripped),
    "Race-recheck query against intro_type='early-access-100' must be gone",
  );
});
