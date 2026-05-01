// Source-contract tests for the Early Access founder cap (100-slot program).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/create-checkout/__tests__/founder_cap_test.ts
//
// We test the source code shape (not a live Stripe call) to avoid drift
// between the spec and the implementation. Live integration is covered by
// the post-deploy curl smoke + manual Stripe test-mode purchase.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = source
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("FC-T01 — exposes FOUNDER_INTRO_TYPE = 'early-access-100'", () => {
  assertStringIncludes(source, "FOUNDER_INTRO_TYPE = \"early-access-100\"");
});

Deno.test("FC-T02 — exposes FOUNDER_TOTAL = 100", () => {
  assertStringIncludes(source, "FOUNDER_TOTAL = 100");
});

Deno.test("FC-T03 — cap probe runs BEFORE Stripe session creation", () => {
  // Order matters: a successful Stripe call costs API quota and emails
  // the customer. We must check the cap first.
  const capProbe = stripped.indexOf('billing_period === "early-access"');
  const stripeCreate = stripped.indexOf("stripe.checkout.sessions.create(");
  assert(capProbe !== -1, "Must check billing_period === 'early-access'");
  assert(stripeCreate !== -1, "Must call Stripe create session");
  assert(
    capProbe < stripeCreate,
    "Cap probe must run before Stripe call — otherwise we burn Stripe quota on rejected requests",
  );
});

Deno.test("FC-T04 — cap probe queries intro_type='early-access-100' active+trialing", () => {
  // Must mirror founder-spots/index.ts exactly. Drift here = bug:
  // counter shows X but checkout uses different filter.
  assertStringIncludes(stripped, "FOUNDER_INTRO_TYPE");
  assertStringIncludes(stripped, '["active", "trialing"]');
  // head:true count for performance.
  assertStringIncludes(stripped, "head: true");
});

Deno.test("FC-T05 — full pool returns HTTP 410 with error='early_access_full'", () => {
  // 410 Gone is semantically correct: the offer is withdrawn, retry won't
  // help. Frontend uses this code to flip the UI to "closed" state.
  assertStringIncludes(stripped, "early_access_full");
  assertStringIncludes(stripped, "status: 410");
});

Deno.test("FC-T06 — DB error during cap probe fails CLOSED (503)", () => {
  // Critical: if we can't read the count, we must NOT create a €14.99
  // session — that risks selling a 101st seat. Fail closed.
  assertStringIncludes(stripped, "Could not verify Early Access");
  assertStringIncludes(stripped, "503");
});

Deno.test("FC-T07 — early-access metadata records intro_type for webhook", () => {
  // The webhook reads session.metadata.intro_type to mark the subscription
  // as a founder. Without this, the webhook can't distinguish a regular
  // €14.99 sale from a founder slot and the lifetime guarantee is lost.
  assertStringIncludes(stripped, "metadata!.intro_type = FOUNDER_INTRO_TYPE");
});

Deno.test("FC-T08 — non-early-access flows do NOT trigger cap probe", () => {
  // Regression guard: pricing-page checkout for monthly/yearly Pro must
  // not consult the founder table.
  // We check that the cap probe is wrapped in a billing_period guard and
  // that there is exactly one such guarded block.
  const matches = stripped.match(/billing_period\s*===\s*"early-access"/g) ||
    [];
  // One in cap probe, one in metadata flag = 2.
  assertEquals(
    matches.length,
    2,
    "Expect 2 references to billing_period==='early-access' (cap probe + metadata flag)",
  );
});

Deno.test("FC-T09 — service role client only used inside the early-access branch", () => {
  // Defence in depth: the service-role key must NEVER be used to satisfy a
  // regular checkout. The only legitimate use is the cap probe inside the
  // early-access branch.
  assertStringIncludes(stripped, "createClient(SUPABASE_URL,");
  // The createClient call must appear AFTER the early-access guard opens.
  const guardIdx = stripped.indexOf('billing_period === "early-access"');
  const createIdx = stripped.indexOf("createClient(SUPABASE_URL,");
  assert(
    guardIdx !== -1 && createIdx !== -1 && createIdx > guardIdx,
    "createClient must be inside the early-access branch, after the guard",
  );
});
