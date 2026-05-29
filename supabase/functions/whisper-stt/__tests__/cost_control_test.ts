// Deno-runtime tests for whisper-stt cost-control helpers (v24.3, 2026-05-02).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/whisper-stt/__tests__/cost_control_test.ts
//
// Scope: pure helpers + tier-quota constants. Live network paths (OpenAI,
// Supabase RPC) are out of scope; covered by smoke tests after deploy.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Pure helpers live in cost_control.ts so this import does NOT boot the
// edge function's HTTP server (which would grab port 8000 at module load).
import {
  decodeBase64,
  detectVoiceTier,
  estimateSecondsFromBytes,
  MAX_AUDIO_B64,
  MAX_BINARY_BYTES,
  SECONDS_PER_CALL_MAX,
  TIER_MONTHLY_SECONDS,
} from "../cost_control.ts";

// ---- estimateSecondsFromBytes ----------------------------------------------

Deno.test("estimateSecondsFromBytes — 0 bytes ⇒ 0 seconds", () => {
  assertEquals(estimateSecondsFromBytes(0), 0);
});

Deno.test("estimateSecondsFromBytes — negative input ⇒ 0 seconds", () => {
  assertEquals(estimateSecondsFromBytes(-1), 0);
});

Deno.test("estimateSecondsFromBytes — 8192 bytes ⇒ 1 second @ 64 kbps", () => {
  // 64 kbps = 8 KB/s, so 8192 bytes is exactly 1 second.
  assertEquals(estimateSecondsFromBytes(8192), 1);
});

Deno.test("estimateSecondsFromBytes — rounds up partial seconds", () => {
  // Math.ceil(8193 / 8192) = 2; we err toward over-counting in the guard.
  assertEquals(estimateSecondsFromBytes(8193), 2);
});

Deno.test("estimateSecondsFromBytes — 10 MB ⇒ ~1280 seconds (~21 min)", () => {
  // 10 * 1024 * 1024 / 8192 = 1280.
  assertEquals(estimateSecondsFromBytes(10 * 1024 * 1024), 1280);
});

// ---- decodeBase64 ----------------------------------------------------------

Deno.test("decodeBase64 — round-trips known string", () => {
  const original = new Uint8Array([0xde, 0xad, 0xbe, 0xef]);
  const b64 = btoa(String.fromCharCode(...original));
  const decoded = decodeBase64(b64);
  assertEquals(decoded, original);
});

Deno.test("decodeBase64 — empty string ⇒ empty array", () => {
  assertEquals(decodeBase64("").byteLength, 0);
});

// ---- TIER_MONTHLY_SECONDS contract -----------------------------------------

Deno.test("TIER_MONTHLY_SECONDS — free tier is zero (voice is paid)", () => {
  assertEquals(TIER_MONTHLY_SECONDS.free, 0);
});

Deno.test("TIER_MONTHLY_SECONDS — basic tier is 5 hours", () => {
  assertEquals(TIER_MONTHLY_SECONDS.basic, 300 * 60);
});

Deno.test("TIER_MONTHLY_SECONDS — premium tier is 20 hours", () => {
  assertEquals(TIER_MONTHLY_SECONDS.premium, 1200 * 60);
});

Deno.test("TIER_MONTHLY_SECONDS — premium > basic > free", () => {
  assert(
    TIER_MONTHLY_SECONDS.premium > TIER_MONTHLY_SECONDS.basic,
    "premium must exceed basic",
  );
  assert(
    TIER_MONTHLY_SECONDS.basic > TIER_MONTHLY_SECONDS.free,
    "basic must exceed free",
  );
});

// ---- Cap constants ---------------------------------------------------------

Deno.test("MAX_BINARY_BYTES — 10 MB", () => {
  assertEquals(MAX_BINARY_BYTES, 10 * 1024 * 1024);
});

Deno.test("MAX_AUDIO_B64 — covers 10 MB binary with base64 inflation", () => {
  // Base64 inflates by 4/3 (33.3%); 14 MB base64 covers a 10 MB binary
  // with ~0.66 MB of headroom for padding/whitespace.
  assert(
    MAX_AUDIO_B64 >= MAX_BINARY_BYTES * 4 / 3,
    "base64 cap must be ≥ binary cap × 4/3",
  );
});

Deno.test("SECONDS_PER_CALL_MAX — 5 minutes", () => {
  assertEquals(SECONDS_PER_CALL_MAX, 300);
});

// ---- detectVoiceTier (mocked supabase client) ------------------------------

interface MockChain {
  // deno-lint-ignore no-explicit-any
  data: any;
  // deno-lint-ignore no-explicit-any
  error?: any;
}

function makeSb(opts: {
  subscription?: MockChain;
  profile?: MockChain;
  throwOnSubscriptions?: boolean;
}) {
  // Minimal chainable mock that mirrors @supabase/supabase-js's PostgREST
  // builder (.from().select().eq()...maybeSingle()). All chain methods
  // return `this` until the awaited terminator.
  const subBuilder: Record<string, unknown> = {};
  const wireSubChain = () => {
    for (
      const m of ["select", "eq", "in", "order", "limit"]
    ) {
      subBuilder[m] = () => subBuilder;
    }
    subBuilder.maybeSingle = () => Promise.resolve(opts.subscription ?? { data: null });
  };
  wireSubChain();

  const profBuilder: Record<string, unknown> = {};
  const wireProfChain = () => {
    for (const m of ["select", "eq"]) {
      profBuilder[m] = () => profBuilder;
    }
    profBuilder.maybeSingle = () => Promise.resolve(opts.profile ?? { data: null });
  };
  wireProfChain();

  return {
    from: (table: string) => {
      if (table === "subscriptions") {
        if (opts.throwOnSubscriptions) {
          throw new Error("subscriptions table missing");
        }
        return subBuilder;
      }
      if (table === "profiles") return profBuilder;
      throw new Error(`unexpected table: ${table}`);
    },
  };
}

Deno.test("detectVoiceTier — premium subscription ⇒ premium", async () => {
  const sb = makeSb({
    subscription: { data: { tier: "premium", status: "active" } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "premium");
});

Deno.test("detectVoiceTier — basic subscription ⇒ basic", async () => {
  const sb = makeSb({
    subscription: { data: { tier: "basic", status: "active" } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "basic");
});

Deno.test("detectVoiceTier — active sub with no tier set ⇒ basic (paid)", async () => {
  const sb = makeSb({
    subscription: { data: { tier: null, status: "active" } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "basic");
});

Deno.test("detectVoiceTier — lapsed period (status active, expired) ⇒ free", async () => {
  // Apple IAP has no expiry webhook in prod, so a cancelled/refunded sub can
  // read status='active' with a past period end. Must not grant paid voice
  // minutes forever — falls through to profiles (none here) → free.
  const sb = makeSb({
    subscription: {
      data: {
        tier: "premium",
        status: "active",
        current_period_end: new Date(Date.now() - 86_400_000).toISOString(),
      },
    },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "free");
});

Deno.test("detectVoiceTier — future period ⇒ tier honoured", async () => {
  const sb = makeSb({
    subscription: {
      data: {
        tier: "premium",
        status: "active",
        current_period_end: new Date(Date.now() + 86_400_000).toISOString(),
      },
    },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "premium");
});

Deno.test("detectVoiceTier — no subscription, no profile ⇒ free", async () => {
  const sb = makeSb({});
  assertEquals(await detectVoiceTier(sb, "uid-1"), "free");
});

Deno.test("detectVoiceTier — profile.is_pro=true (legacy) ⇒ basic", async () => {
  const sb = makeSb({
    profile: { data: { is_pro: true, subscription_tier: null } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "basic");
});

Deno.test("detectVoiceTier — profile.subscription_tier=premium ⇒ premium", async () => {
  const sb = makeSb({
    profile: { data: { is_pro: false, subscription_tier: "premium" } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "premium");
});

Deno.test("detectVoiceTier — subscriptions table throws ⇒ falls back to profiles", async () => {
  const sb = makeSb({
    throwOnSubscriptions: true,
    profile: { data: { is_pro: true } },
  });
  assertEquals(await detectVoiceTier(sb, "uid-1"), "basic");
});

// ---- Quota math (composition test) -----------------------------------------

Deno.test("quota math — basic tier, 4h59m used + 1m new = under, 4h59m + 2m = over", () => {
  const limit = TIER_MONTHLY_SECONDS.basic; // 18000 sec
  const used = (4 * 60 + 59) * 60; // 17940 sec
  assert(used + 60 <= limit, "1 more minute should fit");
  assert(used + 120 > limit, "2 more minutes must overflow");
});

Deno.test("quota math — free tier blocks any duration > 0", () => {
  const limit = TIER_MONTHLY_SECONDS.free;
  assertEquals(limit, 0);
  assert(0 + 1 > limit, "even 1 second is over the free limit");
});

// ---- Source-code contract: handler wires the gate + RPCs -------------------

Deno.test("contract — index.ts uses requireUserWithRateLimit", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, "requireUserWithRateLimit");
  assertStringIncludes(src, 'bucket: "whisper-stt"');
});

Deno.test("contract — index.ts calls get_voice_usage and add_voice_usage RPCs", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, '"get_voice_usage"');
  assertStringIncludes(src, '"add_voice_usage"');
});

Deno.test("contract — index.ts requests verbose_json from Whisper for duration", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  assertStringIncludes(src, '"verbose_json"');
});

Deno.test("contract — index.ts returns 402 for free tier and quota-exceeded", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // Both error paths must surface as Payment Required so the client can
  // distinguish them from generic 4xx and prompt an upgrade.
  assertStringIncludes(src, "402");
});

Deno.test("contract — raw OpenAI error body is NOT echoed to the client", async () => {
  // Leak guard: a failed Whisper call must log the upstream detail
  // server-side (truncated) and hand the client a generic message. The
  // OpenAI error body can carry request IDs and org/quota hints.
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  const stripped = src
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  // The pre-fix bug was `jsonError(error, response.status)` where `error`
  // was `await response.text()` of the OpenAI failure.
  assert(
    !/jsonError\(\s*error\s*,/.test(stripped),
    "raw upstream error text must not be passed to jsonError — leak guard",
  );
  assertStringIncludes(src, '"Transcription failed"');
});
