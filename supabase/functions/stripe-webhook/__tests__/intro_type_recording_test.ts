// Source-contract tests for intro_type recording in stripe-webhook.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/stripe-webhook/__tests__/intro_type_recording_test.ts
//
// We test the source code shape (not a live Stripe webhook delivery) to
// avoid drift between the spec and the implementation.
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

Deno.test("IT-T01 — webhook reads metadata.intro_type from session", () => {
  assertStringIncludes(stripped, "metadata.intro_type");
});

Deno.test("IT-T02 — introType is mutable (let, not const) for race downgrade", () => {
  // The race guard rewrites introType to null when the slot is lost.
  // It must be a `let`, not a `const`.
  const introTypeDeclaration = stripped.match(
    /(let|const)\s+introType\s*:\s*string\s*\|\s*null/,
  );
  assert(
    introTypeDeclaration && introTypeDeclaration[1] === "let",
    "introType must be declared with `let` so the race guard can downgrade it to null",
  );
});

Deno.test("IT-T03 — race re-check queries by intro_type='early-access-100'", () => {
  // The webhook MUST re-check the cap before recording. Otherwise two
  // users who both pass create-checkout's check could both end up with
  // intro_type='early-access-100' and we'd oversell the program.
  assertStringIncludes(stripped, '"early-access-100"');
  assertStringIncludes(stripped, "founder cap recheck");
});

Deno.test("IT-T04 — race re-check excludes the user's own row (idempotent)", () => {
  // Stripe redelivers webhooks. If we re-process our own checkout.completed
  // and our row is already in the table with status='active', counting it
  // would trip the cap on legitimate re-processing.
  assertStringIncludes(stripped, '.neq("user_id", userId)');
});

Deno.test("IT-T05 — race-loss path sets introType = null and warns", () => {
  // When count >= 100, log warn (not error — the user's payment is fine,
  // they just don't get the lifetime guarantee) and downgrade.
  assertStringIncludes(stripped, "founder slot lost in race");
  // The downgrade itself:
  assert(
    /introType\s*=\s*null\s*;/.test(stripped),
    "Race-loss branch must assign introType = null",
  );
});

Deno.test("IT-T06 — subscriptions upsert includes intro_type field", () => {
  // The whole point of this work — the column must actually be written.
  assertStringIncludes(stripped, "intro_type: introType");
});

Deno.test("IT-T07 — race guard runs ONLY when introType is the founder value", () => {
  // Regression: don't run the expensive count query for every checkout.
  assertStringIncludes(
    stripped,
    'introType === "early-access-100"',
  );
});

Deno.test("IT-T08 — DB error in race recheck does NOT strip the flag", () => {
  // Transient DB error should not penalise the user. create-checkout
  // already verified at session-create time. We log and continue.
  assertStringIncludes(stripped, "founder cap recheck failed, granting flag");
});

Deno.test("IT-T09 — race guard placed BEFORE profiles upsert and subscriptions upsert", () => {
  // Order matters: if we upsert subscriptions first with intro_type set,
  // and THEN do the recheck, the count includes our own row and we'd
  // incorrectly trip the cap.
  const recheckIdx = stripped.indexOf("founder cap recheck");
  const profilesUpsertIdx = stripped.indexOf('supabase.from("profiles").upsert');
  const subsUpsertIdx = stripped.indexOf('supabase.from("subscriptions").upsert');
  assert(recheckIdx !== -1, "Recheck block must exist");
  assert(profilesUpsertIdx !== -1, "profiles upsert must exist");
  assert(subsUpsertIdx !== -1, "subscriptions upsert must exist");
  assert(
    recheckIdx < profilesUpsertIdx,
    "Race recheck must run before profiles upsert",
  );
  assert(
    recheckIdx < subsUpsertIdx,
    "Race recheck must run before subscriptions upsert",
  );
});
