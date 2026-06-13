// gateway_test.ts — regression-lock the LLM egress gateway security guarantees.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { pseudonymize, rehydrate } from "../pseudonymizer.ts";
import { validateNoPii } from "../validator.ts";
import {
  EgressPiiLeakError,
  prepareEgress,
  rehydrateOutput,
} from "../gateway.ts";

// ─── pseudonymizer ──────────────────────────────────────────────────────────

Deno.test(
  "PSEUDO-01 — email/id/hetu/phone become stable reversible tokens",
  () => {
    const input =
      "Contact matti.virtanen@example.fi, isikukood 38001010000, " +
      "phone +372 5123 4567.";
    const r = pseudonymize(input);
    assert(!r.text.includes("matti.virtanen@example.fi"), "email leaked");
    assert(!r.text.includes("38001010000"), "ee_id leaked");
    assert(r.text.includes("EMAIL_1"), "no EMAIL token");
    assert(r.text.includes("ID_EE_1"), "no ID_EE token");
    assertEquals(r.map["EMAIL_1"], "matti.virtanen@example.fi");
    assertEquals(r.map["ID_EE_1"], "38001010000");
  }
);

Deno.test(
  "PSEUDO-02 — same real value reuses the same token (co-reference)",
  () => {
    const r = pseudonymize("a@b.com wrote to a@b.com about c@d.com");
    // a@b.com -> EMAIL_1 (twice), c@d.com -> EMAIL_2
    assertEquals(r.counts["EMAIL"], 3);
    assertEquals(Object.keys(r.map).length, 2);
    assertEquals((r.text.match(/EMAIL_1/g) ?? []).length, 2);
    assertEquals((r.text.match(/EMAIL_2/g) ?? []).length, 1);
  }
);

Deno.test(
  "PSEUDO-03 — rehydrate restores real values, PERSON_10 not clobbered by PERSON_1",
  () => {
    const map: Record<string, string> = { PERSON_1: "Aho", PERSON_10: "Koski" };
    const out = rehydrate("PERSON_10 met PERSON_1", map);
    assertEquals(out, "Koski met Aho");
  }
);

Deno.test("PSEUDO-04 — public-record citations are preserved", () => {
  const r = pseudonymize(
    "Per KHO 2024:25 and RKHKo 3-3-1-99-2024 the claim holds."
  );
  assert(r.text.includes("KHO 2024:25"), "public citation scrubbed");
  assert(r.text.includes("3-3-1-99-2024"), "public case id scrubbed");
});

// ─── validator ──────────────────────────────────────────────────────────────

Deno.test("VAL-01 — clean text passes", () => {
  const v = validateNoPii("PERSON_1 filed under EMAIL_1 per KHO 2024:25.");
  assert(v.clean);
  assertEquals(Object.keys(v.leaks).length, 0);
});

Deno.test("VAL-02 — surviving email/id/hetu are detected", () => {
  const v = validateNoPii(
    "leaked real@email.fi and 38001010000 and 010180-123A"
  );
  assert(!v.clean);
  assert(v.leaks["email"] >= 1);
  assert(v.leaks["ee_id"] >= 1);
  assert(v.leaks["fi_hetu"] >= 1);
});

// ─── gateway: fail-closed ───────────────────────────────────────────────────

Deno.test(
  "GW-01 — special tier with clean scrub returns scrubbed text + map",
  async () => {
    const r = await prepareEgress({
      text: "Client matti.virtanen@example.fi, code 38001010000.",
      sensitivity: "special",
      destination: "test",
      // no anthropicApiKey -> regex-only floor; structured PII is fully covered
    });
    assert(!r.text.includes("matti.virtanen@example.fi"));
    assert(!r.text.includes("38001010000"));
    assert(r.manifest.validated_clean);
    assertEquals(r.map["EMAIL_1"], "matti.virtanen@example.fi");
  }
);

Deno.test(
  "GW-02 — special tier THROWS when structured PII survives",
  async () => {
    // Force a leak: an email shape the pseudonymizer's regex can't catch is hard
    // to construct (regex is the same), so simulate via a haiku fetcher that
    // re-injects raw PII (models the 'Haiku undid the scrub' failure mode).
    const evilFetcher: typeof fetch = () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            content: [{ type: "text", text: "leaked back: real@leak.fi" }],
            usage: { input_tokens: 1, output_tokens: 1 },
          }),
          { status: 200 }
        )
      );
    await assertThrowsAsync(
      () =>
        prepareEgress({
          text: "PERSON_1 contact",
          sensitivity: "special",
          destination: "test",
          anthropicApiKey: "sk-test",
          haikuPass: true,
          fetcher: evilFetcher,
        }),
      EgressPiiLeakError
    );
  }
);

Deno.test(
  "GW-03 — standard tier does NOT throw on residual PII (logs only)",
  async () => {
    const evilFetcher: typeof fetch = () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            content: [{ type: "text", text: "back: real@leak.fi" }],
            usage: { input_tokens: 1, output_tokens: 1 },
          }),
          { status: 200 }
        )
      );
    const r = await prepareEgress({
      text: "PERSON_1 contact",
      sensitivity: "standard",
      destination: "test",
      anthropicApiKey: "sk-test",
      haikuPass: true,
      fetcher: evilFetcher,
    });
    assertEquals(r.manifest.validated_clean, false);
  }
);

Deno.test(
  "GW-04 — manifest carries counts + sha256, never real values",
  async () => {
    const r = await prepareEgress({
      text: "Email a@b.com twice: a@b.com",
      sensitivity: "standard",
      destination: "anthropic:test",
    });
    assertEquals(r.manifest.redactions["EMAIL"], 2);
    assertEquals(r.manifest.destination, "anthropic:test");
    assert(/^[0-9a-f]{64}$/.test(r.manifest.payload_sha256));
    const blob = JSON.stringify(r.manifest);
    assert(!blob.includes("a@b.com"), "manifest leaked a real value");
  }
);

Deno.test(
  "GW-05 — rehydrateOutput restores real values in an LLM draft",
  async () => {
    const r = await prepareEgress({
      text: "Draft for matti.virtanen@example.fi",
      sensitivity: "special",
      destination: "test",
    });
    const fakeDraft = `Dear ${Object.keys(r.map)[0]}, your case...`;
    const restored = rehydrateOutput(fakeDraft, r.map);
    assert(restored.includes("matti.virtanen@example.fi"));
  }
);

// small async-throws helper (std assertThrowsAsync was removed in newer std)
async function assertThrowsAsync(
  fn: () => Promise<unknown>,
  // deno-lint-ignore no-explicit-any
  ErrorClass: new (...args: any[]) => Error
): Promise<void> {
  let threw = false;
  try {
    await fn();
  } catch (e) {
    threw = true;
    assert(
      e instanceof ErrorClass,
      `expected ${ErrorClass.name}, got ${String(e)}`
    );
  }
  assert(threw, "expected function to throw");
}
