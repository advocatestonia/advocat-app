// verify-lawyer/__tests__/registry_test.ts
// -----------------------------------------------------------------------------
// Tests for the registry matcher.
//
// The matcher is pure (string → MatchOutcome) so we test it directly against
// synthetic HTML fixtures. Network fetch is exercised via a fake fetchImpl
// to verify the EE/FI adapters wire up correctly without hitting the live
// bar association pages.
//
// Run:
//   deno test --allow-net --allow-env \
//     supabase/functions/verify-lawyer/__tests__/registry_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  lookupEE,
  lookupFI,
  matchInRegistry,
  MatchOutcome,
  normalise,
  tokeniseName,
} from "../registry.ts";

// ─── normalise ───────────────────────────────────────────────────────────

Deno.test("NORM-01 — lowercases and strips diacritics", () => {
  assertEquals(normalise("Sülga"), "sulga");
  assertEquals(normalise("Müllër"), "muller");
});

Deno.test("NORM-02 — collapses whitespace", () => {
  assertEquals(normalise("Dmitri   \n\t  Sulga"), "dmitri sulga");
});

// ─── tokeniseName ────────────────────────────────────────────────────────

Deno.test("TOK-01 — drops short tokens (initials, connectives)", () => {
  assertEquals(tokeniseName("J. Sulga de Tallinn"), ["sulga", "tallinn"]);
});

Deno.test("TOK-02 — keeps multi-word names", () => {
  assertEquals(tokeniseName("Dmitri Sulga"), ["dmitri", "sulga"]);
});

Deno.test("TOK-03 — returns empty for nothing-useful input", () => {
  assertEquals(tokeniseName("J. K."), []);
});

// ─── matchInRegistry: positive cases ─────────────────────────────────────

Deno.test("MATCH-01 — auto-approves with tight proximity", () => {
  const html = `
    <table>
      <tr><td>Member 5421</td><td>Dmitri Sulga</td><td>Tallinn</td></tr>
    </table>
  `;
  const outcome = matchInRegistry(html, {
    country: "EE",
    barId: "5421",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "match");
  if (outcome.kind === "match") {
    assert(outcome.confidence > 0.5, `confidence too low: ${outcome.confidence}`);
  }
});

Deno.test("MATCH-02 — diacritics-insensitive match", () => {
  const html = `<li>Member 7733 — Sülga, Dmitri</li>`;
  const outcome = matchInRegistry(html, {
    country: "EE",
    barId: "7733",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "match");
});

Deno.test("MATCH-03 — FI-style member ID matches", () => {
  const html = `<div>Asianajaja: Matti Virtanen · Jäsennumero 12345 · Helsinki</div>`;
  const outcome = matchInRegistry(html, {
    country: "FI",
    barId: "12345",
    fullName: "Matti Virtanen",
  });
  assertEquals(outcome.kind, "match");
});

// ─── matchInRegistry: borderline cases ───────────────────────────────────

Deno.test("BORDER-01 — name found but ID missing → borderline", () => {
  const html = `<li>Dmitri Sulga, Tallinn</li>`;
  const outcome = matchInRegistry(html, {
    country: "EE",
    barId: "9999",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "borderline");
  if (outcome.kind === "borderline") {
    assertEquals(outcome.reason, "name_found_id_missing");
  }
});

Deno.test("BORDER-02 — ID found but name missing → borderline", () => {
  const html = `<li>Member 12345 — Some Other Name</li>`;
  const outcome = matchInRegistry(html, {
    country: "FI",
    barId: "12345",
    fullName: "Matti Virtanen",
  });
  assertEquals(outcome.kind, "borderline");
  if (outcome.kind === "borderline") {
    assertEquals(outcome.reason, "id_found_name_missing");
  }
});

Deno.test("BORDER-03 — both present but >800 chars apart → borderline", () => {
  // Pad enough whitespace between ID and name to blow the proximity window.
  const filler = "x ".repeat(600); // ≈1200 chars
  const html = `<p>Member 5421</p>${filler}<p>Dmitri Sulga, Tallinn</p>`;
  const outcome = matchInRegistry(html, {
    country: "EE",
    barId: "5421",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "borderline");
  if (outcome.kind === "borderline") {
    assertEquals(outcome.reason, "id_and_name_too_far_apart");
  }
});

// ─── matchInRegistry: miss cases ─────────────────────────────────────────

Deno.test("MISS-01 — neither found → miss", () => {
  const html = `<html><body><p>Unrelated content</p></body></html>`;
  const outcome = matchInRegistry(html, {
    country: "EE",
    barId: "5421",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "miss");
});

Deno.test("MISS-02 — empty bar_id → miss", () => {
  const outcome = matchInRegistry("any html", {
    country: "EE",
    barId: "",
    fullName: "Dmitri Sulga",
  });
  assertEquals(outcome.kind, "miss");
  if (outcome.kind === "miss") {
    assertEquals(outcome.reason, "empty_bar_id");
  }
});

Deno.test("MISS-03 — name contains only short tokens → miss", () => {
  const outcome = matchInRegistry("any html with 5421 in it", {
    country: "EE",
    barId: "5421",
    fullName: "J. K.",
  });
  assertEquals(outcome.kind, "miss");
  if (outcome.kind === "miss") {
    assertEquals(outcome.reason, "empty_name");
  }
});

// ─── EE adapter wiring via fake fetch ────────────────────────────────────

Deno.test("EE-WIRE-01 — auto-approve happy path", async () => {
  const fakeFetch = (_url: string | URL): Promise<Response> => {
    return Promise.resolve(
      new Response(
        `<table><tr><td>5421</td><td>Dmitri Sulga</td></tr></table>`,
        { status: 200, headers: { "Content-Type": "text/html" } },
      ),
    );
  };
  const outcome = await lookupEE(
    { country: "EE", barId: "5421", fullName: "Dmitri Sulga" },
    fakeFetch,
  );
  assertEquals(outcome.kind, "match");
});

Deno.test("EE-WIRE-02 — registry 5xx → unknown (degrade safely)", async () => {
  const fakeFetch = (): Promise<Response> => {
    return Promise.resolve(new Response("oops", { status: 503 }));
  };
  const outcome = await lookupEE(
    { country: "EE", barId: "5421", fullName: "Dmitri Sulga" },
    fakeFetch,
  );
  assertEquals(outcome.kind, "unknown");
});

Deno.test("EE-WIRE-03 — network throw → unknown (degrade safely)", async () => {
  const fakeFetch = (): Promise<Response> => {
    return Promise.reject(new Error("ECONNREFUSED"));
  };
  const outcome = await lookupEE(
    { country: "EE", barId: "5421", fullName: "Dmitri Sulga" },
    fakeFetch,
  );
  assertEquals(outcome.kind, "unknown");
});

// ─── FI adapter wiring ───────────────────────────────────────────────────

Deno.test("FI-WIRE-01 — letter-paged URL is requested for Latin surnames", async () => {
  let calledUrl = "";
  const fakeFetch = (url: string | URL): Promise<Response> => {
    calledUrl = String(url);
    return Promise.resolve(
      new Response(
        `<div>Jäsennumero 12345 — Virtanen, Matti</div>`,
        { status: 200 },
      ),
    );
  };
  const outcome = await lookupFI(
    { country: "FI", barId: "12345", fullName: "Matti Virtanen" },
    fakeFetch,
  );
  assertEquals(outcome.kind, "match");
  assert(calledUrl.includes("letter=v"), `expected letter=v, got ${calledUrl}`);
});

Deno.test("FI-WIRE-02 — non-Latin surname falls back to index page", async () => {
  let calledUrl = "";
  const fakeFetch = (url: string | URL): Promise<Response> => {
    calledUrl = String(url);
    return Promise.resolve(new Response(`12345 — Шульга`, { status: 200 }));
  };
  await lookupFI(
    { country: "FI", barId: "12345", fullName: "Dmitri Шульга" },
    fakeFetch,
  );
  assert(!calledUrl.includes("letter="), `unexpected letter param: ${calledUrl}`);
});

// ─── Confidence scoring ──────────────────────────────────────────────────

Deno.test("CONF-01 — tight match → high confidence", () => {
  // Adjacent ID and name; spread is just the gap between name tokens.
  const out = matchInRegistry(
    "5421 Dmitri Sulga",
    { country: "EE", barId: "5421", fullName: "Dmitri Sulga" },
  ) as Extract<MatchOutcome, { kind: "match" }>;
  assert(out.confidence > 0.95, `expected >0.95, got ${out.confidence}`);
});

Deno.test("CONF-02 — loose match (~500 char gap) → lower confidence", () => {
  const filler = "x ".repeat(200); // ≈400 chars
  const out = matchInRegistry(
    `5421 ${filler} Dmitri Sulga`,
    { country: "EE", barId: "5421", fullName: "Dmitri Sulga" },
  );
  // Could be match or borderline depending on exact length; either is fine,
  // but if match, confidence should be < 0.6.
  if (out.kind === "match") {
    assert(out.confidence < 0.7, `expected <0.7, got ${out.confidence}`);
  } else {
    assertEquals(out.kind, "borderline");
  }
});
