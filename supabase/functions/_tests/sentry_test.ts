// sentry_test.ts
// -----------------------------------------------------------------------------
// Unit tests for _shared/sentry.ts.
//
//   S01  — hashUserId is deterministic and bounded
//   S02  — hashUserId returns "anon" for empty input
//   S03  — looksLikePii catches free-text emails
//   S04  — looksLikePii catches FI case-number patterns
//   S05  — looksLikePii is false for harmless strings
//   S06  — scrubUrl redacts PII-named query params
//   S07  — scrubUrl returns "[invalid url]" on parse failure
//   S08  — scrubPii drops events whose message contains an email
//   S09  — scrubPii drops events whose exception value contains a case number
//   S10  — scrubPii replaces user.email with a hashed id, never email
//   S11  — scrubPii deletes request.data and request.cookies outright
//   S12  — scrubPii redacts sensitive headers but keeps others
//   S13  — scrubPii redacts PII-named extras
//   S14  — scrubPii redacts breadcrumb data + messages
//   S15  — withSentry passes Response through on success
//   S16  — withSentry re-throws after capture so caller sees original error
//   S17  — withSentry is a no-op (no init crash) when SENTRY_DSN is absent
//
// Run with:
//   deno test --allow-env --allow-net \
//     supabase/functions/_tests/sentry_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertNotEquals,
  assertRejects,
  assertStrictEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Ensure no DSN is set — keeps Sentry in no-op mode and avoids network calls.
Deno.env.delete("SENTRY_DSN");

const {
  scrubPii,
  scrubUrl,
  hashUserId,
  looksLikePii,
  withSentry,
} = await import("../_shared/sentry.ts");

// ───────────────────────── helpers ─────────────────────────

function mkEvent(partial: Record<string, unknown> = {}): any {
  return { event_id: "test", ...partial };
}

function mkReq(url = "https://example.test/fn"): Request {
  return new Request(url, { method: "POST" });
}

// ───────────────────────── tests ───────────────────────────

Deno.test("S01 hashUserId is deterministic + bounded", () => {
  const a = hashUserId("user-123");
  const b = hashUserId("user-123");
  assertEquals(a, b);
  assert(a.length <= 12, `hash too long: ${a}`);
  assertNotEquals(a, "user-123", "hash must not leak input verbatim");
});

Deno.test("S02 hashUserId returns 'anon' for empty input", () => {
  assertEquals(hashUserId(), "anon");
  assertEquals(hashUserId(""), "anon");
});

Deno.test("S03 looksLikePii catches free-text email", () => {
  assert(looksLikePii("user dmitri.sulga@example.com failed login"));
  assert(looksLikePii("test@a.co"));
});

Deno.test("S04 looksLikePii catches FI case-number patterns", () => {
  assert(looksLikePii("case 5500/R/75170/25 reopened"));
  assert(looksLikePii("hetu 010180-123A flagged"));
});

Deno.test("S05 looksLikePii is false for harmless strings", () => {
  assert(!looksLikePii("anthropic 429 rate limit"));
  assert(!looksLikePii("invalid json body"));
  assert(!looksLikePii(""));
});

Deno.test("S06 scrubUrl redacts PII-named query params", () => {
  const out = scrubUrl(
    "https://api.advocat.ee/fn?case_id=abc-123&page=2&email=a@b.co",
  );
  assertStringIncludes(out, "case_id=%5BREDACTED%5D");
  assertStringIncludes(out, "email=%5BREDACTED%5D");
  assertStringIncludes(out, "page=2"); // safe param preserved
});

Deno.test("S07 scrubUrl returns sentinel on invalid input", () => {
  assertEquals(scrubUrl("not-a-url"), "[invalid url]");
});

Deno.test("S08 scrubPii drops event when message contains email", () => {
  const event = mkEvent({ message: "lookup failed for foo@bar.com" });
  assertStrictEquals(scrubPii(event), null);
});

Deno.test("S09 scrubPii drops event when exception value contains case num", () => {
  const event = mkEvent({
    exception: { values: [{ type: "Error", value: "row 5500/R/75170/25 missing" }] },
  });
  assertStrictEquals(scrubPii(event), null);
});

Deno.test("S10 scrubPii replaces user.email with hashed id only", () => {
  const event = mkEvent({
    user: { id: "uuid-xyz", email: "leaky@bad.com", username: "leaky" },
  });
  // deno-lint-ignore no-explicit-any
  const out = scrubPii(event) as any;
  assert(out, "event must survive");
  assertEquals(out.user.email, undefined, "email must be stripped");
  assertEquals(out.user.username, undefined, "username must be stripped");
  assert(out.user.id, "id should be present (hashed)");
  assertNotEquals(out.user.id, "uuid-xyz", "id must be hashed, not raw");
});

Deno.test("S11 scrubPii drops request.data and request.cookies", () => {
  const event = mkEvent({
    request: {
      url: "https://api.advocat.ee/fn",
      data: { user_message: "sensitive chat" },
      cookies: { session: "secret" },
      headers: { "content-type": "application/json" },
    },
  });
  // deno-lint-ignore no-explicit-any
  const out = scrubPii(event) as any;
  assertEquals(out.request.data, undefined);
  assertEquals(out.request.cookies, undefined);
});

Deno.test("S12 scrubPii redacts sensitive headers but keeps others", () => {
  const event = mkEvent({
    request: {
      url: "https://api.advocat.ee/fn",
      headers: {
        "Authorization": "Bearer abc.def.ghi",
        "Cookie": "session=x",
        "Stripe-Signature": "t=1,v1=...",
        "Content-Type": "application/json",
        "X-Trace-Id": "trace-1234",
      },
    },
  });
  // deno-lint-ignore no-explicit-any
  const out = scrubPii(event) as any;
  assertEquals(out.request.headers["Authorization"], "[REDACTED]");
  assertEquals(out.request.headers["Cookie"], "[REDACTED]");
  assertEquals(out.request.headers["Stripe-Signature"], "[REDACTED]");
  assertEquals(out.request.headers["Content-Type"], "application/json");
  assertEquals(out.request.headers["X-Trace-Id"], "trace-1234");
});

Deno.test("S13 scrubPii redacts PII-named extras", () => {
  const event = mkEvent({
    extra: {
      case_id: "abc-123",
      thread_id: "thr-1",
      retries: 3,
      anthropic_status: 429,
    },
  });
  // deno-lint-ignore no-explicit-any
  const out = scrubPii(event) as any;
  assertEquals(out.extra.case_id, "[REDACTED]");
  assertEquals(out.extra.thread_id, "[REDACTED]");
  assertEquals(out.extra.retries, 3); // safe key kept
  assertEquals(out.extra.anthropic_status, 429);
});

Deno.test("S14 scrubPii sanitises breadcrumb data and messages", () => {
  const event = mkEvent({
    breadcrumbs: [
      {
        category: "fetch",
        message: "POST /draft email=leak@y.co",
        data: { case_id: "c-1", status: 200 },
      },
      { category: "log", message: "normal log line" },
    ],
  });
  // deno-lint-ignore no-explicit-any
  const out = scrubPii(event) as any;
  assertEquals(out.breadcrumbs[0].message, "[REDACTED]");
  assertEquals(out.breadcrumbs[0].data.case_id, "[REDACTED]");
  assertEquals(out.breadcrumbs[0].data.status, 200);
  assertEquals(out.breadcrumbs[1].message, "normal log line");
});

Deno.test("S15 withSentry passes Response through unchanged on success", async () => {
  const wrapped = withSentry("test-fn", async (_req) => {
    return new Response("ok", { status: 200 });
  });
  const res = await wrapped(mkReq());
  assertEquals(res.status, 200);
  assertEquals(await res.text(), "ok");
});

Deno.test("S16 withSentry re-throws after capture so caller sees original", async () => {
  const wrapped = withSentry("test-fn", async (_req) => {
    throw new Error("boom-original");
  });
  await assertRejects(
    () => wrapped(mkReq()),
    Error,
    "boom-original",
  );
});

Deno.test("S17 withSentry no-op safe when SENTRY_DSN is absent", async () => {
  // Sanity: env is unset at module load (see top of file).
  assertEquals(Deno.env.get("SENTRY_DSN"), undefined);
  const wrapped = withSentry("no-dsn-fn", async (_req) => {
    return new Response("dev-mode", { status: 200 });
  });
  const res = await wrapped(mkReq());
  assertEquals(res.status, 200);
  assertEquals(await res.text(), "dev-mode");
});
