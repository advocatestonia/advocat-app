// scrub_body_test.ts — regression-lock the shared body-scrub helper.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { scrubAnthropicBody, scrubText } from "../scrub_body.ts";

Deno.test(
  "SCRUB-01 — strips identifiers from system + string messages, keeps names",
  () => {
    const body = {
      system: "Advisor for isikukood 38001010000.",
      messages: [
        { role: "user", content: "Aho's IBAN is EE382200221020145685, help." },
      ],
      max_tokens: 1024,
    };
    // deno-lint-ignore no-explicit-any
    const out = scrubAnthropicBody(body) as any;
    assert(!out.system.includes("38001010000"), "isikukood leaked in system");
    assert(
      !out.messages[0].content.includes("EE382200221020145685"),
      "IBAN leaked"
    );
    assert(out.messages[0].content.includes("Aho"), "name was stripped");
    assertEquals(out.max_tokens, 1024, "non-text fields preserved");
  }
);

Deno.test("SCRUB-02 — handles text-block array content", () => {
  const body = {
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: "code 38001010000" },
          { type: "image", source: { data: "..." } },
        ],
      },
    ],
  };
  // deno-lint-ignore no-explicit-any
  const out = scrubAnthropicBody(body) as any;
  assert(!out.messages[0].content[0].text.includes("38001010000"));
  assertEquals(out.messages[0].content[1].type, "image", "non-text block kept");
});

Deno.test("SCRUB-03 — malformed body returns unchanged (never throws)", () => {
  assertEquals(scrubAnthropicBody(null), null);
  assertEquals(scrubAnthropicBody("nope"), "nope");
  assertEquals(scrubAnthropicBody(42), 42);
});

Deno.test("SCRUB-04 — does not mutate the input body", () => {
  const body = { system: "isikukood 38001010000" };
  scrubAnthropicBody(body);
  assertEquals(body.system, "isikukood 38001010000", "input was mutated");
});

Deno.test(
  "SCRUB-05 — scrubText identifiers-only by default, full on request",
  () => {
    // Compound surname the regex is designed to catch (stem + suffix).
    // Standalone bare-suffix names ("Aho") are a known heuristic gap covered
    // by the gateway's Haiku name-pass, not this regex floor.
    const t = "Virtanen 38001010000";
    assert(scrubText(t).includes("Virtanen"), "default should keep names");
    assert(!scrubText(t).includes("38001010000"), "default should strip id");
    assert(
      !scrubText(t, { full: true }).includes("Virtanen"),
      "full should strip name"
    );
  }
);
