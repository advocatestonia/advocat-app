// halt_rail_test.ts — coverage for the serious-case detector and appenders.
//
// Run with:
//   deno test -A supabase/functions/_shared/__tests__/halt_rail_test.ts

import { assert, assertEquals } from "https://deno.land/std@0.177.0/testing/asserts.ts";
import {
  appendHaltRailToResponse,
  appendHaltRailToSystem,
  detectCrisis,
  detectLangFromMessage,
  detectSeriousCase,
  extractLargestEuroAmount,
  type HaltDetection,
  prependCrisisBanner,
  recordHaltRailTrigger,
} from "../halt_rail.ts";

// ─── detectCrisis (suicide / self-harm) ──────────────────────────────────────

Deno.test("crisis: English suicidal ideation fires", () => {
  const d = detectCrisis("i want to kill myself, nothing matters");
  assertEquals(d.isCrisis, true);
});

Deno.test("crisis: Finnish itsemurha fires", () => {
  assertEquals(detectCrisis("ajattelen itsemurhaa").isCrisis, true);
});

Deno.test("crisis: Estonian enesetapp fires", () => {
  assertEquals(detectCrisis("mõtlen enesetapule, ei jaksa enam").isCrisis, true);
});

Deno.test("crisis: Russian не хочу жить fires", () => {
  assertEquals(detectCrisis("я больше не хочу жить").isCrisis, true);
});

Deno.test("crisis: benign legal query does NOT fire", () => {
  assertEquals(
    detectCrisis("how do I appeal my deportation order").isCrisis,
    false,
  );
});

Deno.test("crisis: bare word 'suicide' in news context does NOT fire", () => {
  // Single-word mention without first-person distress phrasing.
  assertEquals(detectCrisis("the suicide rate statistics in 2024").isCrisis, false);
});

Deno.test("crisis: non-string input is safe (no throw, false)", () => {
  assertEquals(detectCrisis(null).isCrisis, false);
  assertEquals(detectCrisis(undefined).isCrisis, false);
  assertEquals(detectCrisis(123 as unknown).isCrisis, false);
});

Deno.test("prependCrisisBanner: prepends helpline + 🆘 when in crisis", () => {
  const out = prependCrisisBanner(
    "Here is some legal info.",
    { isCrisis: true, reason: "crisis:test" },
    "i want to die",
  );
  assert(out.startsWith("🆘"), "crisis banner must lead the reply");
  assert(out.includes("Here is some legal info."), "original text preserved");
  // English-anchored helpline numbers present.
  assert(out.includes("112"), "EU emergency number present");
});

Deno.test("prependCrisisBanner: Finnish message gets FI helpline", () => {
  const out = prependCrisisBanner(
    "Vastaus.",
    { isCrisis: true, reason: "crisis:test" },
    "en jaksa enää elää, haluan kuolla",
  );
  assert(out.includes("09 2525 0111"), "MIELI crisis line present");
});

Deno.test("prependCrisisBanner: idempotent (no double 🆘)", () => {
  const once = prependCrisisBanner(
    "x",
    { isCrisis: true, reason: "r" },
    "want to die",
  );
  const twice = prependCrisisBanner(
    once,
    { isCrisis: true, reason: "r" },
    "want to die",
  );
  assertEquals(once, twice);
});

Deno.test("prependCrisisBanner: no-op when not in crisis", () => {
  assertEquals(
    prependCrisisBanner("reply", { isCrisis: false, reason: "" }),
    "reply",
  );
});

// ─── detectSeriousCase ──────────────────────────────────────────────────────

Deno.test("detect: Russian deportation query fires", () => {
  const d = detectSeriousCase("меня хотят депортировать что делать");
  assert(d.isSerious);
  assertEquals(d.category, "deportation");
});

Deno.test("detect: Finnish käännyttäminen fires", () => {
  const d = detectSeriousCase("Migri päätti käännyttämisestä mitä teen");
  assert(d.isSerious);
  assertEquals(d.category, "deportation");
});

Deno.test("detect: Estonian väljasaatmine fires", () => {
  const d = detectSeriousCase("PPA tegi väljasaatmise otsuse");
  assert(d.isSerious);
  assertEquals(d.category, "deportation");
});

Deno.test("detect: English criminal charge fires", () => {
  const d = detectSeriousCase("I want to fight a criminal charge in Estonia");
  assert(d.isSerious);
  assertEquals(d.category, "criminal");
});

Deno.test("detect: Estonian ainuhooldusõigus fires", () => {
  const d = detectSeriousCase("kuidas saada lapsele ainuhooldusõigust");
  assert(d.isSerious);
  assertEquals(d.category, "custody");
});

Deno.test("detect: big claim €50000 fires above threshold", () => {
  const d = detectSeriousCase("claim €50000 in damages");
  assert(d.isSerious);
  assertEquals(d.category, "big_claim");
  assertEquals(d.matchedAmount, 50000);
});

Deno.test("detect: ECHR English fires", () => {
  const d = detectSeriousCase("ECHR application against Finland");
  assert(d.isSerious);
  assertEquals(d.category, "echr");
});

Deno.test("detect: ECHR Russian (ЕСПЧ) fires", () => {
  const d = detectSeriousCase("хочу подать жалобу в ЕСПЧ на Финляндию");
  assert(d.isSerious);
  assertEquals(d.category, "echr");
});

Deno.test("detect: benign message does not fire", () => {
  const d = detectSeriousCase("сколько стоит подписка Pro?");
  assertEquals(d.isSerious, false);
  assertEquals(d.category, null);
});

// ─── P5 regression tests: production smoke gaps closed 2026-05-15 ──────────
//
// These three queries fired in production smoke (P5 of Bentley batch) but
// were silently missed by the detector. Each represents a real
// linguistic gap the consilium did not surface during the A7 unit tests.
// Pin them so they never regress.

Deno.test("detect: Finnish deportointi (colloquial) fires", () => {
  // Live caller wrote "deportointi päätöksestä" instead of the formal
  // "käännyttämispäätöksestä". Both must trigger the deportation rail.
  const d = detectSeriousCase(
    "miten teen valituslupahakemuksen KHO:lle deportointi päätöksestä",
  );
  assert(d.isSerious);
  assertEquals(d.category, "deportation");
});

Deno.test("detect: Russian 'опека на ребёнка' (preposition variant) fires", () => {
  // The keyword table originally only contained "опека ребёнка" (genitive,
  // formal). Live users almost always write the colloquial preposition form.
  const d = detectSeriousCase("развод и опека на ребёнка, муж тоже хочет");
  assert(d.isSerious);
  assertEquals(d.category, "custody");
});

Deno.test("detect: Estonian 'kuriteo tunnustega' fires", () => {
  // The Estonian criminal-investigation stems missed "kuritegu / kuriteo"
  // — actually the most common term in police summons text.
  const d = detectSeriousCase("uurimine algatatud minu vastu kuriteo tunnustega");
  assert(d.isSerious);
  assertEquals(d.category, "criminal");
});

// ─── FIX-WAVE 12 regression tests: multilingual inflection gaps (2026-05-20) ──
//
// Dept5 live probes (8 multilingual variants of ECHR + deportation prompts)
// found 3 FAILs where Finnish illative / Estonian allative inflections
// bypassed the stem table. Pin those exact prompts so they never regress.

Deno.test("detect: Finnish ECHR illative 'ihmisoikeustuomioistuimeen' fires", () => {
  // Live FI probe FAIL → now PASS. Illative case (…-tuimeen) didn't match
  // the unflected stem "ihmisoikeustuomioistuin"; new prefix stem
  // "ihmisoikeustuomioistui" catches it.
  const d = detectSeriousCase("valitus Euroopan ihmisoikeustuomioistuimeen");
  assert(d.isSerious);
  assertEquals(d.category, "echr");
});

Deno.test("detect: Estonian ECHR allative 'Inimõiguste Kohtule' fires", () => {
  // Live ET probe FAIL → now PASS. Allative case ("Kohtule") didn't match
  // nominative "kohus"; new multi-word stem "inimõiguste koht" catches all
  // declensions (kohtule / kohut / kohust / kohtus).
  const d = detectSeriousCase("kaebuse Euroopa Inimõiguste Kohtule esitamine");
  assert(d.isSerious);
  assertEquals(d.category, "echr");
});

Deno.test("detect: Estonian deportation particle-split 'saadetakse … välja' fires", () => {
  // Live ET probe FAIL → now PASS. "Mind saadetakse Eestist välja" splits
  // the particle "välja" from the verb stem "saadeta-"; old keyword
  // "väljasaatm" (compound form) missed it. New stems "saadeta" + multi-word
  // "välja saade" both catch this construction.
  const d = detectSeriousCase("Mind saadetakse Eestist välja järgmisel kuul");
  assert(d.isSerious);
  assertEquals(d.category, "deportation");
});

Deno.test("detect: small claim does not fire", () => {
  const d = detectSeriousCase("хозяин не возвращает €500 депозита");
  assertEquals(d.isSerious, false);
});

Deno.test("detect: claim at threshold (20000) does not fire (strictly greater)", () => {
  const d = detectSeriousCase("My claim is exactly €20000");
  assertEquals(d.isSerious, false);
});

Deno.test("detect: claim just above threshold fires", () => {
  const d = detectSeriousCase("My claim is €20500");
  assert(d.isSerious);
  assertEquals(d.category, "big_claim");
});

Deno.test("detect: bare year 2026 does not trigger big_claim", () => {
  const d = detectSeriousCase("the deadline is 2026 EUR ago"); // contrived
  // 2026 is rejected by the year-filter; big_claim must NOT fire.
  // Other categories might fire in real text but here nothing else does.
  assertEquals(d.category, null);
});

Deno.test("detect: empty / non-string input is safe", () => {
  assertEquals(detectSeriousCase("").isSerious, false);
  // deno-lint-ignore no-explicit-any
  assertEquals(detectSeriousCase(null as any).isSerious, false);
  // deno-lint-ignore no-explicit-any
  assertEquals(detectSeriousCase(undefined as any).isSerious, false);
  // deno-lint-ignore no-explicit-any
  assertEquals(detectSeriousCase(123 as any).isSerious, false);
});

Deno.test("detect: word-boundary prevents substring false-positive", () => {
  // "kriminaalipoliitikko" contains "kriminaali" but should NOT fire on the
  // "rikossyyte" keyword. We test "kriminaalsüüdistuse" which DOES contain
  // the full keyword "kriminaalsüüdistus" and SHOULD fire.
  const d = detectSeriousCase("kriminaalsüüdistuse asjaolud");
  assert(d.isSerious);
  assertEquals(d.category, "criminal");
});

// ─── extractLargestEuroAmount ───────────────────────────────────────────────

Deno.test("amount: various formats", () => {
  assertEquals(extractLargestEuroAmount("claim €50000"), 50000);
  assertEquals(extractLargestEuroAmount("claim 50 000 EUR"), 50000);
  assertEquals(extractLargestEuroAmount("claim 50,000 euros"), 50000);
  assertEquals(extractLargestEuroAmount("claim 50.000€"), 50000);
  assertEquals(extractLargestEuroAmount("€19.99 per month"), 0); // below 1000-digit cutoff
  assertEquals(extractLargestEuroAmount("€100000"), 100000);
});

Deno.test("amount: picks the largest", () => {
  assertEquals(
    extractLargestEuroAmount("first €5000 then €25000 final €15000"),
    25000,
  );
});

Deno.test("amount: no currency marker → 0", () => {
  // 50000 alone, no €/EUR/евро → not counted as a money amount.
  assertEquals(extractLargestEuroAmount("the case 50000 is interesting"), 0);
});

// ─── appendHaltRailToSystem ─────────────────────────────────────────────────

Deno.test("system-append: no-op when not serious", () => {
  const base = "You are Advocat.";
  const out = appendHaltRailToSystem(base, {
    isSerious: false,
    category: null,
    reason: "",
    matchedAmount: 0,
  });
  assertEquals(out, base);
});

Deno.test("system-append: injects sentinel when serious", () => {
  const out = appendHaltRailToSystem("You are Advocat.", {
    isSerious: true,
    category: "criminal",
    reason: "keyword:criminal:test",
    matchedAmount: 0,
  });
  assert(out.includes("## HALT-RAIL — SERIOUS CASE DETECTED"));
  assert(out.includes("asianajaja"));
  assert(out.includes("vandeadvokaat"));
});

Deno.test("system-append: idempotent", () => {
  const det = {
    isSerious: true,
    category: "criminal" as const,
    reason: "x",
    matchedAmount: 0,
  };
  const once = appendHaltRailToSystem("base", det);
  const twice = appendHaltRailToSystem(once, det);
  assertEquals(once, twice);
});

Deno.test("system-append: safe with non-string", () => {
  // deno-lint-ignore no-explicit-any
  const out = appendHaltRailToSystem(null as any, {
    isSerious: true,
    category: "criminal",
    reason: "x",
    matchedAmount: 0,
  });
  assert(out.includes("HALT-RAIL"));
});

// ─── appendHaltRailToResponse ───────────────────────────────────────────────

Deno.test("response-append: no-op when not serious", () => {
  const out = appendHaltRailToResponse("regular reply", {
    isSerious: false,
    category: null,
    reason: "",
    matchedAmount: 0,
  });
  assertEquals(out, "regular reply");
});

Deno.test("response-append: appends Russian banner for Cyrillic message", () => {
  const out = appendHaltRailToResponse(
    "AI ответ.",
    {
      isSerious: true,
      category: "deportation",
      reason: "x",
      matchedAmount: 0,
    },
    "меня хотят депортировать",
  );
  assert(out.includes("Это серьёзная правовая ситуация"));
  assert(out.includes("asianajaja**") && out.includes("(Финляндия)"));
});

Deno.test("response-append: appends Finnish banner for FI message", () => {
  const out = appendHaltRailToResponse(
    "AI vastaa.",
    {
      isSerious: true,
      category: "deportation",
      reason: "x",
      matchedAmount: 0,
    },
    "minua ollaan käännyttämässä Suomesta",
  );
  assert(out.includes("Tämä on vakava oikeudellinen tilanne"));
  assert(out.includes("asianajajan** (Suomi)"));
});

Deno.test("response-append: appends Estonian banner for ET message", () => {
  const out = appendHaltRailToResponse(
    "AI vastab.",
    {
      isSerious: true,
      category: "custody",
      reason: "x",
      matchedAmount: 0,
    },
    "kuidas saada lapsele ainuhooldusõigust kohtus",
  );
  assert(out.includes("See on tõsine õiguslik olukord"));
});

Deno.test("response-append: appends English banner for EN message", () => {
  const out = appendHaltRailToResponse(
    "AI reply.",
    {
      isSerious: true,
      category: "echr",
      reason: "x",
      matchedAmount: 0,
    },
    "I want to file an ECHR application against Finland for unfair trial",
  );
  assert(out.includes("This is a serious legal situation"));
  assert(out.includes("asianajaja** (Finland)"));
});

Deno.test("response-append: idempotent (no double banner)", () => {
  const det = {
    isSerious: true,
    category: "criminal" as const,
    reason: "x",
    matchedAmount: 0,
  };
  const once = appendHaltRailToResponse("reply", det, "уголовное дело");
  const twice = appendHaltRailToResponse(once, det, "уголовное дело");
  assertEquals(once, twice);
});

Deno.test("response-append: safe with non-string", () => {
  // deno-lint-ignore no-explicit-any
  const out = appendHaltRailToResponse(null as any, {
    isSerious: true,
    category: "criminal",
    reason: "x",
    matchedAmount: 0,
  });
  // Banner attached to empty base → still contains the marker.
  assert(out.includes("⚠️"));
});

// ─── detectLangFromMessage ──────────────────────────────────────────────────

Deno.test("lang: Russian Cyrillic", () => {
  assertEquals(detectLangFromMessage("привет как дела"), "ru");
});

Deno.test("lang: Finnish", () => {
  assertEquals(
    detectLangFromMessage("Hei minä olen suomalainen ja teen testin"),
    "fi",
  );
});

Deno.test("lang: Estonian", () => {
  assertEquals(
    detectLangFromMessage("Tere ma olen eestlane ja teen testi õigesti"),
    "et",
  );
});

Deno.test("lang: English", () => {
  assertEquals(
    detectLangFromMessage("hello I want to file a claim with the court"),
    "en",
  );
});

// ─── recordHaltRailTrigger (P5 metric write) ────────────────────────────

const SERIOUS: HaltDetection = {
  isSerious: true,
  category: "deportation",
  reason: "keyword:deportation:депорт",
  matchedAmount: 0,
};
const BIG_CLAIM: HaltDetection = {
  isSerious: true,
  category: "big_claim",
  reason: "amount:50000EUR>threshold:20000",
  matchedAmount: 50000,
};
const NOT_SERIOUS: HaltDetection = {
  isSerious: false,
  category: null,
  reason: "",
  matchedAmount: 0,
};

async function withFetchMock<T>(
  handler: (req: Request) => Response | Promise<Response>,
  fn: () => Promise<T>,
): Promise<{ requests: Request[]; result: T }> {
  const original = globalThis.fetch;
  const requests: Request[] = [];
  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const req = input instanceof Request ? input : new Request(input, init);
    requests.push(req.clone());
    return await handler(req);
  }) as typeof fetch;
  try {
    const result = await fn();
    return { requests, result };
  } finally {
    globalThis.fetch = original;
  }
}

Deno.test("recordHaltRailTrigger: writes one row on serious detection", async () => {
  const { requests } = await withFetchMock(
    () => new Response(null, { status: 201 }),
    () =>
      recordHaltRailTrigger({
        detection: SERIOUS,
        language: "ru",
        userId: "11111111-1111-1111-1111-111111111111",
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "sk_test",
      }),
  );
  assertEquals(requests.length, 1);
  const url = new URL(requests[0].url);
  assertEquals(url.pathname, "/rest/v1/halt_rail_triggers");
  assertEquals(requests[0].method, "POST");
  const body = await requests[0].json();
  assertEquals(body.category, "deportation");
  assertEquals(body.language, "ru");
  assertEquals(body.user_id, "11111111-1111-1111-1111-111111111111");
  assert(typeof body.reason === "string" && body.reason.length > 0);
  assertEquals(body.amount_eur, null);
});

Deno.test("recordHaltRailTrigger: big_claim writes amount_eur", async () => {
  const { requests } = await withFetchMock(
    () => new Response(null, { status: 201 }),
    () =>
      recordHaltRailTrigger({
        detection: BIG_CLAIM,
        language: "en",
        userId: null,
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "sk_test",
      }),
  );
  const body = await requests[0].json();
  assertEquals(body.category, "big_claim");
  assertEquals(body.amount_eur, 50000);
  assertEquals(body.user_id, null);
});

Deno.test("recordHaltRailTrigger: no-op when not serious", async () => {
  const { requests } = await withFetchMock(
    () => new Response(null, { status: 500 }), // would fail if called
    () =>
      recordHaltRailTrigger({
        detection: NOT_SERIOUS,
        language: "ru",
        userId: null,
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "sk_test",
      }),
  );
  assertEquals(requests.length, 0);
});

Deno.test("recordHaltRailTrigger: no-op when service-role key empty", async () => {
  const { requests } = await withFetchMock(
    () => new Response(null, { status: 500 }),
    () =>
      recordHaltRailTrigger({
        detection: SERIOUS,
        language: "ru",
        userId: null,
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "",
      }),
  );
  assertEquals(requests.length, 0);
});

Deno.test("recordHaltRailTrigger: swallows PostgREST 4xx without throwing", async () => {
  // Returns 400 — must NOT throw. The caller fire-and-forgets so a thrown
  // error here would surface as an unhandled-promise warning in Edge logs.
  const { requests } = await withFetchMock(
    () => new Response("bad column", { status: 400 }),
    () =>
      recordHaltRailTrigger({
        detection: SERIOUS,
        language: "ru",
        userId: null,
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "sk_test",
      }),
  );
  assertEquals(requests.length, 1); // request fired, but call resolved
});

Deno.test("recordHaltRailTrigger: swallows network failure", async () => {
  await withFetchMock(
    () => {
      throw new TypeError("network down");
    },
    () =>
      recordHaltRailTrigger({
        detection: SERIOUS,
        language: "ru",
        userId: null,
        supabaseUrl: "https://example.supabase.co",
        serviceRoleKey: "sk_test",
      }),
  );
  // No assertion needed — the test passes iff the call resolves.
});

// =============================================================================
// 2026-05-27 — extended language detection (17 locales)
// =============================================================================

Deno.test("detectLangFromMessage: detects DE", () => {
  assertEquals(
    detectLangFromMessage("ich werde aus Deutschland abgeschoben"),
    "de",
  );
});

Deno.test("detectLangFromMessage: detects ES (¿/¡/ñ)", () => {
  assertEquals(
    detectLangFromMessage("¿me están deportando de España?"),
    "es",
  );
});

Deno.test("detectLangFromMessage: detects FR", () => {
  assertEquals(detectLangFromMessage("je suis expulsé de France"), "fr");
});

Deno.test("detectLangFromMessage: detects IT", () => {
  assertEquals(detectLangFromMessage("sono deportato dall'Italia"), "it");
});

Deno.test("detectLangFromMessage: detects PL (ą/ę/ł)", () => {
  assertEquals(detectLangFromMessage("jestem deportowany z Polski"), "pl");
});

Deno.test("detectLangFromMessage: detects RO", () => {
  assertEquals(detectLangFromMessage("sunt deportat din România"), "ro");
});

Deno.test("detectLangFromMessage: detects SV", () => {
  assertEquals(detectLangFromMessage("jag deporteras från Sverige"), "sv");
});

Deno.test("detectLangFromMessage: detects TR (ş/ğ)", () => {
  assertEquals(
    detectLangFromMessage("İsveç'ten sınır dışı ediliyorum"),
    "tr",
  );
});

Deno.test("detectLangFromMessage: detects LT", () => {
  assertEquals(
    detectLangFromMessage("aš esu deportuojamas iš Lietuvos"),
    "lt",
  );
});

Deno.test("detectLangFromMessage: detects LV", () => {
  assertEquals(detectLangFromMessage("mani izraida no Latvijas"), "lv");
});

Deno.test("detectLangFromMessage: detects UK (i/ї/є/ґ)", () => {
  assertEquals(detectLangFromMessage("мене депортують з України"), "uk");
});

Deno.test("detectLangFromMessage: detects AR", () => {
  assertEquals(
    detectLangFromMessage("سيتم ترحيلي من ألمانيا"),
    "ar",
  );
});

Deno.test("detectLangFromMessage: detects FA (می‌ / هستم)", () => {
  assertEquals(
    detectLangFromMessage("من از ایران اخراج می‌شوم"),
    "fa",
  );
});

Deno.test("detectLangFromMessage: empty string defaults to en (not ru)", () => {
  assertEquals(detectLangFromMessage(""), "en");
});

Deno.test("detectLangFromMessage: FI still detected after extension", () => {
  assertEquals(
    detectLangFromMessage("minua ollaan käännyttämässä Suomesta"),
    "fi",
  );
});

Deno.test("detectLangFromMessage: ET still detected after extension", () => {
  assertEquals(
    detectLangFromMessage("mind saadetakse Soomest välja"),
    "et",
  );
});

Deno.test("detectLangFromMessage: RU still detected (Cyrillic)", () => {
  assertEquals(detectLangFromMessage("меня хотят депортировать"), "ru");
});

Deno.test("BANNER: has all 17 locales (no missing key fallback)", async () => {
  // Read source and grep-assert each locale code appears as a key.
  const src = await Deno.readTextFile(
    new URL("../halt_rail.ts", import.meta.url),
  );
  const locales = [
    "ar", "de", "en", "es", "et", "fa", "fi", "fr", "it",
    "lt", "lv", "pl", "ro", "ru", "sv", "tr", "uk",
  ];
  // Locate the BANNER const block and check each key appears.
  const bannerStart = src.indexOf("const BANNER");
  assert(bannerStart > 0, "BANNER const not found");
  const bannerEnd = src.indexOf("\n};", bannerStart);
  const block = src.slice(bannerStart, bannerEnd);
  for (const l of locales) {
    assert(
      new RegExp(`\\b${l}:\\s*\\n? *"`).test(block),
      `BANNER missing key for ${l}`,
    );
  }
});
