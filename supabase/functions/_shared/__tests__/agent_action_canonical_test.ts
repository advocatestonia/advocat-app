// Regression tests for the WAVE 2 W2-09 fix — canonical-JSON HMAC
// serialisation + visible-field projection for write tools.
// -----------------------------------------------------------------------------
// Smoking gun this suite locks down:
//   - Postgres JSONB round-trip normalises key order; the old
//     JSON.stringify(input) hashed an insertion-order string that
//     differed from the post-roundtrip shape → every legitimate Approve
//     tap might 409 in production.
//   - The action_id signed args_sha256 only, but the user-visible card
//     content (subject / to / body) was a separate derivation. Homograph
//     attacks on `to` could pass the hash without the user noticing.
//
// What we now guarantee:
//   1. Reordering keys at any depth does NOT change the hash.
//   2. JSON.parse(JSON.stringify(args)) round-trip is hash-stable.
//   3. A Postgres-JSONB simulation (length-then-lex-sorted keys) is
//      hash-stable too.
//   4. Visible-field homograph attempts on `to` are caught even when
//      the rest of the input is identical.
//   5. Different `body` content with the SAME length is caught via
//      body_sha256_prefix.
//   6. The signed payload carries an audience tag — tokens signed for
//      one purpose cannot be replayed against another.

import {
  assert,
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  AGENT_ACTION_AUDIENCE,
  canonicalJsonStringify,
  hashToolInput,
  issueActionId,
  verifyActionId,
  visibleProjectionForTool,
} from "../agent_action.ts";

const SECRET = "test-secret-canonical-w2-09";

// ---------------------------------------------------------------------------
// 1. canonicalJsonStringify — low-level invariant
// ---------------------------------------------------------------------------

Deno.test("canonicalJsonStringify: sorts keys lexicographically", () => {
  const a = canonicalJsonStringify({ b: 1, a: 2, c: 3 });
  const b = canonicalJsonStringify({ a: 2, b: 1, c: 3 });
  const c = canonicalJsonStringify({ c: 3, a: 2, b: 1 });
  assertEquals(a, b);
  assertEquals(b, c);
  assertEquals(a, `{"a":2,"b":1,"c":3}`);
});

Deno.test("canonicalJsonStringify: deep-sorts nested objects", () => {
  const a = canonicalJsonStringify({ z: { y: 1, x: 2 }, a: { b: 1, c: 2 } });
  const b = canonicalJsonStringify({ a: { c: 2, b: 1 }, z: { x: 2, y: 1 } });
  assertEquals(a, b);
});

Deno.test("canonicalJsonStringify: preserves array order", () => {
  const a = canonicalJsonStringify([3, 1, 2]);
  assertEquals(a, "[3,1,2]");
  // Arrays of objects: each element is canonicalised but order kept.
  const b = canonicalJsonStringify([{ b: 1, a: 2 }, { a: 3, b: 4 }]);
  assertEquals(b, `[{"a":2,"b":1},{"a":3,"b":4}]`);
});

Deno.test("canonicalJsonStringify: drops undefined properties", () => {
  const a = canonicalJsonStringify({ a: 1, b: undefined, c: 3 });
  assertEquals(a, `{"a":1,"c":3}`);
});

Deno.test("canonicalJsonStringify: NaN and Infinity become null", () => {
  assertEquals(canonicalJsonStringify(NaN), "null");
  assertEquals(canonicalJsonStringify(Infinity), "null");
  assertEquals(canonicalJsonStringify(-Infinity), "null");
});

Deno.test("canonicalJsonStringify: handles primitives and null", () => {
  assertEquals(canonicalJsonStringify(null), "null");
  assertEquals(canonicalJsonStringify(undefined), "null");
  assertEquals(canonicalJsonStringify("hello"), `"hello"`);
  assertEquals(canonicalJsonStringify(42), "42");
  assertEquals(canonicalJsonStringify(true), "true");
  assertEquals(canonicalJsonStringify(false), "false");
});

Deno.test("canonicalJsonStringify: escapes strings correctly", () => {
  const a = canonicalJsonStringify({ msg: "a\nb\"c" });
  assertEquals(a, `{"msg":"a\\nb\\"c"}`);
});

// ---------------------------------------------------------------------------
// 2. hashToolInput — JSONB round-trip stability
// ---------------------------------------------------------------------------

Deno.test("hashToolInput: stable across JSON.parse(JSON.stringify) round-trip", async () => {
  const original = {
    to: ["jokela@poliisi.fi"],
    subject: "Vastine asia 5500/R/75170/25",
    body: "Hyvä Tuomari Jokela,\n\nVastauksena vastineeseenne...",
    confirmed: true,
  };
  // Simulate JSON serialisation (as if it had been written to a DB).
  const roundtripped = JSON.parse(JSON.stringify(original));
  const a = await hashToolInput(original, "send_email");
  const b = await hashToolInput(roundtripped, "send_email");
  assertEquals(a, b, "JSON round-trip must preserve hash");
});

Deno.test("hashToolInput: stable across insertion-order variations", async () => {
  // Anthropic might emit keys in any order; Postgres normalises them.
  // Both ends must compute the same hash.
  const anthropicOrder: Record<string, unknown> = {
    to: ["x@y.com"],
    subject: "Hi",
    body: "hello",
    confirmed: true,
  };
  const insertionVariant1: Record<string, unknown> = {
    confirmed: true,
    body: "hello",
    subject: "Hi",
    to: ["x@y.com"],
  };
  const insertionVariant2: Record<string, unknown> = {
    body: "hello",
    to: ["x@y.com"],
    confirmed: true,
    subject: "Hi",
  };
  const h1 = await hashToolInput(anthropicOrder, "send_email");
  const h2 = await hashToolInput(insertionVariant1, "send_email");
  const h3 = await hashToolInput(insertionVariant2, "send_email");
  assertEquals(h1, h2);
  assertEquals(h2, h3);
});

Deno.test("hashToolInput: stable across Postgres JSONB key-length-then-lex normalisation", async () => {
  // Simulate Postgres' canonical jsonb form: keys sorted by length first,
  // then lexicographically (the bug F-005 describes). Our canonical
  // form is pure-lex-sort which is DIFFERENT from Postgres' internal
  // form — but BOTH normalisations land at the same canonical string
  // after canonicalJsonStringify because we re-sort on the way in.
  const original = {
    to: ["x@y.com"],
    subject: "Hi",
    body: "hello",
    confirmed: true,
  };
  // Manually shuffle to look like a Postgres-normalised form.
  const pgNormalised = JSON.parse(
    '{"to":["x@y.com"],"body":"hello","subject":"Hi","confirmed":true}',
  );
  assertEquals(
    await hashToolInput(original, "send_email"),
    await hashToolInput(pgNormalised, "send_email"),
    "Postgres-style normalisation must produce identical hash",
  );
});

Deno.test("hashToolInput: stable across deeply-nested key reordering", async () => {
  const a = {
    to: ["x@y.com"],
    subject: "Hi",
    body: "hello",
    attachments: [
      { name: "a.pdf", size: 100, sha256: "abc" },
      { name: "b.pdf", size: 200, sha256: "def" },
    ],
  };
  const b = {
    subject: "Hi",
    body: "hello",
    attachments: [
      { sha256: "abc", size: 100, name: "a.pdf" }, // keys shuffled
      { size: 200, name: "b.pdf", sha256: "def" }, // keys shuffled
    ],
    to: ["x@y.com"],
  };
  assertEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
  );
});

// ---------------------------------------------------------------------------
// 3. Visible-field projection — attacker forces different visible fields
// ---------------------------------------------------------------------------

Deno.test("hashToolInput: DIFFERENT hash when `to` differs (homograph attack)", async () => {
  // Latin 'o' vs Cyrillic 'о' — identical glyph but different codepoint.
  const latin = { to: ["jokela@poliisi.fi"], subject: "S", body: "b" };
  const cyrillic = { to: ["jоkela@poliisi.fi"], subject: "S", body: "b" }; // Cyrillic о (U+043E)
  const hLatin = await hashToolInput(latin, "send_email");
  const hCyrillic = await hashToolInput(cyrillic, "send_email");
  assertNotEquals(
    hLatin,
    hCyrillic,
    "homograph in `to` MUST change the hash",
  );
});

Deno.test("hashToolInput: DIFFERENT hash when subject differs", async () => {
  const a = { to: ["x@y"], subject: "Hi", body: "b" };
  const b = { to: ["x@y"], subject: "Hello", body: "b" };
  assertNotEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
  );
});

Deno.test("hashToolInput: DIFFERENT hash when body content differs (same length)", async () => {
  // body_sha256_prefix catches length-preserving tampering — e.g.
  // attacker swaps "Approved: yes" for "Approved: no_" (both 13 chars).
  const a = { to: ["x@y"], subject: "S", body: "Approved: yes" };
  const b = { to: ["x@y"], subject: "S", body: "Approved: no_" };
  assertEquals((a.body as string).length, (b.body as string).length);
  assertNotEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
  );
});

Deno.test("hashToolInput: SAME hash when `to` is reordered (set semantics)", async () => {
  // Multiple recipients: order shouldn't matter, sets do.
  const a = { to: ["a@x.com", "b@x.com"], subject: "S", body: "b" };
  const b = { to: ["b@x.com", "a@x.com"], subject: "S", body: "b" };
  assertEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
    "recipient set must be order-independent",
  );
});

Deno.test("hashToolInput: SAME hash when `to` differs only in case", async () => {
  const a = { to: ["Jokela@Poliisi.fi"], subject: "S", body: "b" };
  const b = { to: ["jokela@poliisi.fi"], subject: "S", body: "b" };
  assertEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
    "email address case must be normalised",
  );
});

Deno.test("hashToolInput: DIFFERENT hash when attachment count differs", async () => {
  const a = {
    to: ["x@y"],
    subject: "S",
    body: "b",
    attachments: [{ id: "a" }],
  };
  const b = {
    to: ["x@y"],
    subject: "S",
    body: "b",
    attachments: [{ id: "a" }, { id: "c" }],
  };
  assertNotEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
  );
});

Deno.test("hashToolInput: SAME hash when only non-projected fields change", async () => {
  // The model might add jitter on retry — e.g. a draft_id or
  // in_reply_to. As long as visible fields match, approval stands.
  const a = {
    to: ["x@y"],
    subject: "S",
    body: "b",
    draft_id: "d-1",
  };
  const b = {
    to: ["x@y"],
    subject: "S",
    body: "b",
    draft_id: "d-2", // unrelated jitter
  };
  assertEquals(
    await hashToolInput(a, "send_email"),
    await hashToolInput(b, "send_email"),
  );
});

Deno.test("hashToolInput: unknown write tool falls back to full canonical input", async () => {
  // For tools we don't have a projection for, the full input is hashed.
  // Reordering keys is still safe (canonical-JSON), but ANY field
  // change invalidates the hash.
  const a = await hashToolInput(
    { foo: 1, bar: 2 },
    "some_future_write_tool",
  );
  const b = await hashToolInput(
    { bar: 2, foo: 1 },
    "some_future_write_tool",
  );
  const c = await hashToolInput(
    { foo: 1, bar: 3 }, // bar changed
    "some_future_write_tool",
  );
  assertEquals(a, b);
  assertNotEquals(a, c);
});

Deno.test("visibleProjectionForTool: send_email projection shape", () => {
  const p = visibleProjectionForTool("send_email", {
    to: ["A@X.com", "b@X.com"],
    cc: "c@x.com,d@x.com",
    subject: "  Hello  ",
    body: "Body text",
    attachments: [{ id: "a" }, { id: "b" }],
    draft_id: "ignored",
  });
  assertEquals(p._tool, "send_email");
  assertEquals(p.to, ["a@x.com", "b@x.com"]);
  assertEquals(p.cc, ["c@x.com", "d@x.com"]);
  assertEquals(p.subject, "Hello");
  assertEquals(p.body_length, 9); // utf-8 byte length of "Body text"
  assertEquals(p.has_attachments_count, 2);
  // body_sha256_prefix is set later by hashToolInput.
  assertEquals((p as Record<string, unknown>).draft_id, undefined);
});

// ---------------------------------------------------------------------------
// 4. Audience binding (F-009 prep)
// ---------------------------------------------------------------------------

Deno.test("issueActionId: signed payload carries audience tag", async () => {
  const tok = await issueActionId({
    agent_run_id: "r1",
    user_id: "u1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const payloadB64 = tok.split(".")[0];
  // Decode the base64url payload manually.
  const pad = "=".repeat((4 - (payloadB64.length % 4)) % 4);
  const std = (payloadB64 + pad).replace(/-/g, "+").replace(/_/g, "/");
  const decoded = JSON.parse(atob(std));
  assertEquals(decoded.aud, AGENT_ACTION_AUDIENCE);
  assertEquals(decoded.purpose, "send_email");
});

Deno.test("verifyActionId: rejects tampered audience field", async () => {
  // Forge a token whose payload has a non-agent_approve audience.
  const tok = await issueActionId({
    agent_run_id: "r1",
    user_id: "u1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  // Decode, mutate, re-encode payload — but DO NOT re-sign. The HMAC
  // check is what catches this, but the audience check fires first
  // when the payload survives a length-preserving edit. We can't do a
  // length-preserving aud edit (string lengths differ), so this
  // becomes an hmac_mismatch — both close the hole. We just sanity-
  // check that an aud-stripped token does NOT verify ok.
  const payloadB64 = tok.split(".")[0];
  const pad = "=".repeat((4 - (payloadB64.length % 4)) % 4);
  const std = (payloadB64 + pad).replace(/-/g, "+").replace(/_/g, "/");
  const decoded = JSON.parse(atob(std));
  decoded.aud = "policy_gate"; // attacker tries to reuse for another scheme
  const tamperedJson = JSON.stringify(decoded);
  const tamperedB64 = btoa(tamperedJson)
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const forged = `${tamperedB64}.${tok.split(".")[1]}`;
  const r = await verifyActionId({
    token: forged,
    expected_agent_run_id: "r1",
    expected_user_id: "u1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  // Either audience_mismatch (caught before HMAC) or hmac_mismatch
  // (HMAC over mutated payload doesn't match) — both close the hole.
  assert(
    r.reason === "audience_mismatch" || r.reason === "hmac_mismatch",
    `expected audience or hmac mismatch, got ${r.reason}`,
  );
});

Deno.test("verifyActionId: round-trip after the W2-09 fix still works", async () => {
  // The integration test the production code relies on.
  const input = {
    to: ["jokela@poliisi.fi"],
    subject: "Vastine 5500/R/75170/25",
    body: "Hyvä Tuomari Jokela,\n\nVastine.\n\nKunnioittavasti,\nSulga",
    confirmed: true,
  };
  const sha = await hashToolInput(input, "send_email");
  const tok = await issueActionId({
    agent_run_id: "run-abc",
    user_id: "user-xyz",
    tool_name: "send_email",
    args_sha256: sha,
    secret: SECRET,
    now_ms: 1_000_000,
  });
  // Simulate Postgres round-trip (key reorder).
  const persisted = JSON.parse(JSON.stringify({
    confirmed: true,
    body: input.body,
    subject: input.subject,
    to: input.to,
  }));
  const recomputed = await hashToolInput(persisted, "send_email");
  assertEquals(recomputed, sha, "round-trip hash must match");
  const verify = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-abc",
    expected_user_id: "user-xyz",
    expected_tool_name: "send_email",
    expected_args_sha256: recomputed,
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(verify.ok, true);
});

// ---------------------------------------------------------------------------
// 5. Backwards-compat: hashToolInput without toolName still hashes safely
// ---------------------------------------------------------------------------

Deno.test("hashToolInput: backwards-compat without toolName uses safe full hash", async () => {
  const a = await hashToolInput({ foo: 1, bar: 2 });
  const b = await hashToolInput({ bar: 2, foo: 1 });
  assertEquals(a, b, "no-toolName path must still be canonical");
  const c = await hashToolInput({ foo: 1, bar: 3 });
  assertNotEquals(a, c);
});
