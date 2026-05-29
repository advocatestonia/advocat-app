// redirect_allowlist_test.ts
// -----------------------------------------------------------------------------
// Wave 1 fix P1-08 (2026-05-28) — open-redirect protection.
//
// Run with:
//   deno test --allow-env --allow-read \
//     supabase/functions/_shared/__tests__/redirect_allowlist_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  isAllowedRedirect,
  validateCheckoutRedirects,
} from "../redirect_allowlist.ts";

// --- env reset helpers --------------------------------------------------------

function clearEnv() {
  Deno.env.delete("ALLOWED_REDIRECT_HOSTS");
  Deno.env.delete("ALLOW_LOCALHOST_REDIRECT");
}

// --- isAllowedRedirect --------------------------------------------------------

Deno.test("RA-T01 — advocat.ee root is allowed by default", () => {
  clearEnv();
  assert(isAllowedRedirect("https://advocat.ee/payment-success.html"));
});

Deno.test("RA-T02 — app.advocat.ee subdomain allowed by default", () => {
  clearEnv();
  assert(isAllowedRedirect("https://app.advocat.ee/team/billing/success"));
});

Deno.test("RA-T03 — external domain rejected", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("https://attacker.example/fake-receipt"));
});

Deno.test("RA-T04 — lookalike attacker.advocat.ee.evil.com rejected", () => {
  clearEnv();
  // The suffix check is anchored on ".advocat.ee" — a host ending in
  // ".advocat.ee.evil.com" must NOT match.
  assertFalse(isAllowedRedirect("https://app.advocat.ee.evil.com/x"));
});

Deno.test("RA-T05 — javascript: scheme rejected", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("javascript:alert(1)"));
});

Deno.test("RA-T06 — data: scheme rejected", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("data:text/html,<script>alert(1)</script>"));
});

Deno.test("RA-T07 — file: scheme rejected", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("file:///etc/passwd"));
});

Deno.test("RA-T08 — malformed URL rejected", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("not a url"));
  assertFalse(isAllowedRedirect(""));
});

Deno.test("RA-T09 — localhost rejected without opt-in", () => {
  clearEnv();
  assertFalse(isAllowedRedirect("http://localhost:3000/x"));
});

Deno.test("RA-T10 — localhost allowed when ALLOW_LOCALHOST_REDIRECT=true", () => {
  clearEnv();
  Deno.env.set("ALLOW_LOCALHOST_REDIRECT", "true");
  assert(isAllowedRedirect("http://localhost:3000/x"));
  assert(isAllowedRedirect("http://127.0.0.1/x"));
  clearEnv();
});

Deno.test("RA-T11 — custom allowlist via env", () => {
  clearEnv();
  Deno.env.set(
    "ALLOWED_REDIRECT_HOSTS",
    "example.com,*.example.org",
  );
  assert(isAllowedRedirect("https://example.com/x"));
  assert(isAllowedRedirect("https://api.example.org/x"));
  assertFalse(isAllowedRedirect("https://advocat.ee/x")); // not in custom list
  clearEnv();
});

// --- validateCheckoutRedirects ------------------------------------------------

Deno.test("RA-T12 — defaults pass through when no override", () => {
  clearEnv();
  const r = validateCheckoutRedirects(undefined, undefined, {
    success: "https://advocat.ee/ok",
    cancel: "https://advocat.ee/cancel",
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.success, "https://advocat.ee/ok");
    assertEquals(r.cancel, "https://advocat.ee/cancel");
  }
});

Deno.test("RA-T13 — valid override is accepted", () => {
  clearEnv();
  const r = validateCheckoutRedirects(
    "https://app.advocat.ee/success",
    undefined,
    { success: "https://advocat.ee/ok", cancel: "https://advocat.ee/cancel" },
  );
  assert(r.ok);
  if (r.ok) assertEquals(r.success, "https://app.advocat.ee/success");
});

Deno.test("RA-T14 — external success_url rejected", () => {
  clearEnv();
  const r = validateCheckoutRedirects(
    "https://attacker.example/x",
    undefined,
    { success: "https://advocat.ee/ok", cancel: "https://advocat.ee/cancel" },
  );
  assertFalse(r.ok);
  if (!r.ok) assertEquals(r.reason, "success_url_not_in_allowlist");
});

Deno.test("RA-T15 — external cancel_url rejected", () => {
  clearEnv();
  const r = validateCheckoutRedirects(
    undefined,
    "https://attacker.example/x",
    { success: "https://advocat.ee/ok", cancel: "https://advocat.ee/cancel" },
  );
  assertFalse(r.ok);
  if (!r.ok) assertEquals(r.reason, "cancel_url_not_in_allowlist");
});

Deno.test("RA-T16 — non-string success_url rejected", () => {
  clearEnv();
  // deno-lint-ignore no-explicit-any
  const r = validateCheckoutRedirects(123 as any, undefined, {
    success: "https://advocat.ee/ok",
    cancel: "https://advocat.ee/cancel",
  });
  assertFalse(r.ok);
  if (!r.ok) assertEquals(r.reason, "success_url_not_string");
});

Deno.test("RA-T17 — misconfigured defaults flagged loud", () => {
  clearEnv();
  const r = validateCheckoutRedirects(undefined, undefined, {
    // operator misconfigured ALLOWED_REDIRECT_HOSTS so default is now unsafe
    success: "https://attacker.example/ok",
    cancel: "https://attacker.example/cancel",
  });
  assertFalse(r.ok);
  if (!r.ok) assertEquals(r.reason, "redirect_defaults_not_in_allowlist");
});

Deno.test("RA-T18 — empty string override falls back to default", () => {
  clearEnv();
  const r = validateCheckoutRedirects("", "", {
    success: "https://advocat.ee/ok",
    cancel: "https://advocat.ee/cancel",
  });
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.success, "https://advocat.ee/ok");
    assertEquals(r.cancel, "https://advocat.ee/cancel");
  }
});
