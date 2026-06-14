// router_test.ts — EU-inference routing decisions + dispatch behaviour.
import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { euConfigFromEnv, routeInference } from "../router.ts";
import {
  callEuProvider,
  EuInferenceBlockedError,
  EuProviderNotWiredError,
} from "../dispatch.ts";

const OFF = { mode: "off" as const };
const PREFERRED_NO_EU = { mode: "preferred" as const };
const STRICT_NO_EU = { mode: "strict" as const };
const PREFERRED_EU = {
  mode: "preferred" as const,
  euTextModel: "eu.anthropic.claude-x",
  euTextRegion: "eu-central-1",
  euVisionModel: "eu.vision-x",
  euVisionRegion: "eu-central-1",
};

// ── config ──────────────────────────────────────────────────────────────────
Deno.test("EU-01 — default mode is off", () => {
  assertEquals(euConfigFromEnv({ get: () => undefined }).mode, "off");
});

// ── TIER_0 (raw documents) ────────────────────────────────────────────────────
Deno.test(
  "EU-02 — TIER_0 with no EU vision + off → legacy US but FLAGGED",
  () => {
    const d = routeInference("TIER_0", "claude-haiku", OFF);
    assertEquals(d.target, "legacy_us");
    assertEquals(d.eu_resident, false);
    assert(d.reason.includes("FLAGGED"));
  }
);

Deno.test(
  "EU-03 — TIER_0 with no EU vision + strict → BLOCKED (no US leak)",
  () => {
    const d = routeInference("TIER_0", "claude-haiku", STRICT_NO_EU);
    assertEquals(d.target, "blocked");
    assertEquals(d.model, null);
  }
);

Deno.test("EU-04 — TIER_0 with EU vision → eu_vision in EU", () => {
  const d = routeInference("TIER_0", "claude-haiku", PREFERRED_EU);
  assertEquals(d.target, "eu_vision");
  assertEquals(d.eu_resident, true);
  assertEquals(d.region, "eu-central-1");
});

// ── TIER_1 / TIER_2 (text) ────────────────────────────────────────────────────
Deno.test("EU-05 — off mode is a pass-through to legacy for text", () => {
  const d = routeInference("TIER_1", "claude-opus", OFF);
  assertEquals(d.target, "legacy_us");
  assertEquals(d.eu_resident, false);
});

Deno.test("EU-06 — preferred + EU text model → eu_text in EU", () => {
  const d = routeInference("TIER_1", "claude-opus", PREFERRED_EU);
  assertEquals(d.target, "eu_text");
  assertEquals(d.model, "eu.anthropic.claude-x");
  assertEquals(d.eu_resident, true);
});

Deno.test(
  "EU-07 — preferred but no EU text → legacy US fallback (documented)",
  () => {
    const d = routeInference("TIER_2", "claude-haiku", PREFERRED_NO_EU);
    assertEquals(d.target, "legacy_us");
    assert(d.reason.includes("fallback"));
  }
);

Deno.test("EU-08 — strict + no EU text → BLOCKED (EU-only)", () => {
  const d = routeInference("TIER_1", "claude-opus", STRICT_NO_EU);
  assertEquals(d.target, "blocked");
});

// ── dispatch ──────────────────────────────────────────────────────────────────
Deno.test(
  "EU-09 — dispatch legacy_us returns null (caller uses its path)",
  async () => {
    const d = routeInference("TIER_2", "claude-haiku", OFF);
    const r = await callEuProvider(d, { messages: [] });
    assertEquals(r, null);
  }
);

Deno.test(
  "EU-10 — dispatch blocked throws EuInferenceBlockedError",
  async () => {
    const d = routeInference("TIER_1", "claude-opus", STRICT_NO_EU);
    await assertRejects(
      () => callEuProvider(d, { messages: [] }),
      EuInferenceBlockedError
    );
  }
);

Deno.test(
  "EU-11 — dispatch eu_text throws NotWired until owner wires it",
  async () => {
    const d = routeInference("TIER_1", "claude-opus", PREFERRED_EU);
    await assertRejects(
      () => callEuProvider(d, { messages: [] }),
      EuProviderNotWiredError
    );
  }
);
