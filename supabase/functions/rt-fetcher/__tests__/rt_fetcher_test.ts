// Deno tests for rt-fetcher edge function.
//
// Pure helpers live in ../parser.ts and are imported directly (real ESM,
// real types). Wire-format/contract assertions are text-source tests
// against index.ts so we don't have to boot serve() in unit tests.
//
// Run from supabase/functions/rt-fetcher/ with:
//   deno test --allow-env --allow-read

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  aliasVariants,
  parseMetadata,
  parseStatuteXml,
  renderSectionNum,
  sectionLabel,
  stripAndDecode,
} from "../parser.ts";

const indexSrc = await Deno.readTextFile(new URL("../index.ts", import.meta.url));

// ── Wire format / contract tests ────────────────────────────────────────────

Deno.test("index.ts — POST body shape (worker_id + max_jobs)", () => {
  for (const f of ["worker_id", "max_jobs"]) {
    assertStringIncludes(
      indexSrc,
      `body.${f}`,
      `must read body.${f}`,
    );
  }
});

Deno.test("index.ts — CRON_SECRET auth (x-cron-secret OR Bearer)", () => {
  assertStringIncludes(indexSrc, "CRON_SECRET");
  assertStringIncludes(indexSrc, "x-cron-secret");
  // Header + bearer paths are compared in constant time (timing-oracle fix).
  assertStringIncludes(indexSrc, "timingSafeEqualStr(bearer, CRON_SECRET)");
  assertStringIncludes(indexSrc, "timingSafeEqualStr(headerSecret, CRON_SECRET)");
});

Deno.test("index.ts — idempotent insert (delete-then-insert per act_slug)", () => {
  assertStringIncludes(
    indexSrc,
    'from("law_chunks_v2")\n    .delete()',
  );
  assertStringIncludes(
    indexSrc,
    'from("statute_aliases")\n    .delete()',
  );
});

Deno.test("index.ts — Riigi Teataja base URL, no fake REST API", () => {
  assertStringIncludes(indexSrc, "www.riigiteataja.ee");
  // Catch a regression where someone re-introduces the fake API from
  // the original spec.
  assert(
    !indexSrc.includes("api.riigiteataja.ee"),
    "RT has no JSON/REST API — only the HTML/XML site",
  );
  // Verify per-act XML URL pattern in source
  assertStringIncludes(indexSrc, "/akt/");
  assertStringIncludes(indexSrc, ".xml");
});

Deno.test("index.ts — User-Agent header (good neighbour to RT/Webmedia)", () => {
  assertStringIncludes(indexSrc, '"User-Agent": USER_AGENT');
  assertStringIncludes(indexSrc, "AdvocatBot");
});

Deno.test("index.ts — rate limit at most 2 req/sec/worker", () => {
  const m = indexSrc.match(/REQ_INTERVAL_MS\s*=\s*(\d+)/);
  assert(m, "REQ_INTERVAL_MS constant must exist");
  const ms = parseInt(m![1], 10);
  // 500ms = 2 req/sec — adequate for RT's Cloudflare-fronted infrastructure.
  // <500ms would risk triggering their burst limiter.
  assert(ms >= 500, `REQ_INTERVAL_MS must be >= 500ms, got ${ms}`);
});

Deno.test("index.ts — discovery helper resolveActSlugToGlobalId is exported", () => {
  assertStringIncludes(indexSrc, "export async function resolveActSlugToGlobalId");
  // Discovery hits the abbreviation URL and pulls global_id from response
  // body. This regex must remain in source so the spec-driven test
  // catches accidental refactors.
  assertStringIncludes(indexSrc, "akt\\/(\\d{8,})\\.xml");
});

Deno.test("index.ts — lease guard: only takes status='queued' rows", () => {
  assertStringIncludes(indexSrc, '.eq("status", "queued")');
});

Deno.test("index.ts — error path writes sticky last_error to ingest_jobs", () => {
  // When a discovery / fetch fails, finalizeJob should record the message
  // in last_error so ops can see why a job failed.
  assertStringIncludes(indexSrc, "last_error");
  assertStringIncludes(indexSrc, 'result.status === "failed"');
});

// ── Citation format tests ───────────────────────────────────────────────────

Deno.test("sectionLabel — EE convention: § BEFORE number", () => {
  assertEquals(sectionLabel("TsÜS", "86"), "TsÜS § 86");
  assertEquals(sectionLabel("KarS", "115"), "KarS § 115");
  assertEquals(sectionLabel("HMS", "47"), "HMS § 47");
});

Deno.test("sectionLabel — handles ylaIndeks superscript section numbers", () => {
  assertEquals(sectionLabel("KarS", "100¹"), "KarS § 100¹");
  assertEquals(sectionLabel("VÕS", "1043²"), "VÕS § 1043²");
});

Deno.test("sectionLabel — chapter does NOT appear in label (EE convention)", () => {
  // FI uses "RL 21:1 §" — EE never uses the chapter in citations.
  // Chapter goes into law_chunks_v2.chapter column, not the label.
  assertEquals(sectionLabel("KarS", "115", "9"), "KarS § 115");
});

Deno.test("sectionLabel — never produces `§ N ACT` reversed form", () => {
  // Load-bearing assertion for citation correctness. If this fails,
  // downstream citation grounder will reject every EE citation.
  for (const [abbrev, num] of [["TsÜS", "86"], ["KarS", "115"], ["VÕS", "1043²"]]) {
    const label = sectionLabel(abbrev, num);
    assert(
      !label.startsWith("§"),
      `label must NOT start with §; got "${label}"`,
    );
    assertStringIncludes(label, `${abbrev} § ${num}`);
  }
});

Deno.test("aliasVariants — 6 variants, covers common typos", () => {
  const meta = {
    act_slug: "ee-tsus",
    act_abbrev: "TsÜS",
    act_full_name: "Tsiviilseadustiku üldosa seadus",
    lang: "et",
    source_url: "x",
  };
  const variants = aliasVariants(meta, "86");
  assertEquals(variants.length, 6);
  const aliases = variants.map((v) => v.alias);
  assert(aliases.includes("TsÜS § 86"));
  assert(aliases.includes("Tsiviilseadustiku üldosa seadus § 86"));
  assert(aliases.includes("TsÜS §86"));
  assert(aliases.includes("tsiviilseadustiku üldosa seadus § 86"));
  assert(aliases.includes("tsüs § 86"));
  assert(aliases.includes("§ 86 TsÜS"));
});

Deno.test("aliasVariants — pattern_kind respects DB check constraint", () => {
  // statute_aliases.pattern_kind only accepts {'exact','regex','common_misspelling'}.
  const meta = {
    act_slug: "ee-hms",
    act_abbrev: "HMS",
    act_full_name: "Haldusmenetluse seadus",
    lang: "et",
    source_url: "x",
  };
  for (const v of aliasVariants(meta, "47")) {
    assert(
      ["exact", "regex", "common_misspelling"].includes(v.pattern_kind),
      `pattern_kind "${v.pattern_kind}" violates statute_aliases check constraint`,
    );
  }
  // Canonical variant is 'exact'; reversed is 'common_misspelling'.
  const variants = aliasVariants(meta, "47");
  const canonical = variants.find((v) => v.alias === "HMS § 47");
  const reversed = variants.find((v) => v.alias === "§ 47 HMS");
  assertEquals(canonical?.pattern_kind, "exact");
  assertEquals(reversed?.pattern_kind, "common_misspelling");
});

// ── Helpers: stripAndDecode + renderSectionNum ──────────────────────────────

Deno.test("stripAndDecode — unwraps CDATA and strips tags", () => {
  assertEquals(
    stripAndDecode("<p>foo <b>bar</b> baz</p>"),
    "foo bar baz",
  );
  assertEquals(
    stripAndDecode("<kuvatavNr><![CDATA[(1)]]></kuvatavNr>"),
    "(1)",
  );
});

Deno.test("stripAndDecode — decodes entities and collapses whitespace", () => {
  assertEquals(
    stripAndDecode("&amp;&lt;&gt;&quot;&apos;&nbsp;&#167;"),
    `&<>"' §`,
  );
  assertEquals(
    stripAndDecode("a\n\n  b   c\t\td"),
    "a b c d",
  );
});

Deno.test("renderSectionNum — base number unchanged when no ylaIndeks", () => {
  assertEquals(renderSectionNum("86"), "86");
  assertEquals(renderSectionNum("1043"), "1043");
});

Deno.test("renderSectionNum — appends Unicode superscript for ylaIndeks", () => {
  assertEquals(renderSectionNum("100", "1"), "100¹");
  assertEquals(renderSectionNum("100", "2"), "100²");
  assertEquals(renderSectionNum("100", "12"), "100¹²");
  assertEquals(renderSectionNum("12", "0"), "12⁰");
});

// ── parseMetadata tests ─────────────────────────────────────────────────────

const META_FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<oigusakt>
  <metaandmed>
    <lyhend>TsÜS</lyhend>
    <kehtivus>
      <kehtivuseAlgus>2025-01-01</kehtivuseAlgus>
    </kehtivus>
    <globaalID>131122024048</globaalID>
  </metaandmed>
  <aktinimi><nimi><pealkiri>Tsiviilseadustiku üldosa seadus</pealkiri></nimi></aktinimi>
</oigusakt>`;

Deno.test("parseMetadata — extracts lyhend / globalId / kehtivuseAlgus", () => {
  const md = parseMetadata(META_FIXTURE);
  assertEquals(md.lyhend, "TsÜS");
  assertEquals(md.globalId, "131122024048");
  assertEquals(md.kehtivuseAlgus, "2025-01-01");
  assertEquals(md.kehtivuseLopp, undefined);
});

// ── parseStatuteXml — minimal real-shape fixture ────────────────────────────

const MINIMAL_RT_XML = `<?xml version="1.0" encoding="UTF-8"?>
<oigusakt>
  <metaandmed><lyhend>HMS</lyhend></metaandmed>
  <peatykk id="ptk1">
    <peatykkNr>1</peatykkNr>
    <peatykkPealkiri>ÜLDSÄTTED</peatykkPealkiri>
    <paragrahv id="para1">
      <paragrahvNr>1</paragrahvNr>
      <kuvatavNr><![CDATA[§ 1.]]></kuvatavNr>
      <paragrahvPealkiri>Seaduse ülesanne</paragrahvPealkiri>
      <loige id="para1lg1">
        <sisuTekst>
          <tavatekst>Käesoleva seaduse ülesanne on tagada haldusmenetluse ühtsus.</tavatekst>
        </sisuTekst>
      </loige>
    </paragrahv>
    <paragrahv id="para2">
      <paragrahvNr>2</paragrahvNr>
      <kuvatavNr><![CDATA[§ 2.]]></kuvatavNr>
      <paragrahvPealkiri>Haldusmenetluse mõiste</paragrahvPealkiri>
      <loige id="para2lg1">
        <loigeNr>1</loigeNr>
        <kuvatavNr><![CDATA[(1)]]></kuvatavNr>
        <sisuTekst><tavatekst>Esimene lõige.</tavatekst></sisuTekst>
      </loige>
      <loige id="para2lg2">
        <loigeNr>2</loigeNr>
        <kuvatavNr><![CDATA[(2)]]></kuvatavNr>
        <sisuTekst><tavatekst>Teine lõige.</tavatekst></sisuTekst>
      </loige>
    </paragrahv>
  </peatykk>
  <peatykk id="ptk8">
    <peatykkNr>8</peatykkNr>
    <peatykkPealkiri>RESTORATION</peatykkPealkiri>
    <paragrahv id="para47">
      <paragrahvNr>47</paragrahvNr>
      <kuvatavNr><![CDATA[§ 47.]]></kuvatavNr>
      <paragrahvPealkiri>Menetlustähtaja ennistamine</paragrahvPealkiri>
      <loige id="para47lg1">
        <sisuTekst><tavatekst>Mõjuva põhjusega ennistamise menetlus.</tavatekst></sisuTekst>
      </loige>
    </paragrahv>
    <paragrahv id="para47a">
      <paragrahvNr ylaIndeks="1">47</paragrahvNr>
      <kuvatavNr><![CDATA[§ 47<sup>1</sup>.]]></kuvatavNr>
      <paragrahvPealkiri>Lisanõuded</paragrahvPealkiri>
      <loige id="para47b1lg1">
        <sisuTekst><tavatekst>Täiendavad reeglid.</tavatekst></sisuTekst>
      </loige>
    </paragrahv>
  </peatykk>
</oigusakt>`;

Deno.test("parseStatuteXml — extracts every <paragrahv>", () => {
  const sections = parseStatuteXml(MINIMAL_RT_XML);
  assertEquals(sections.length, 4);
  const nums = sections.map((s) => s.num);
  assert(nums.includes("1"));
  assert(nums.includes("2"));
  assert(nums.includes("47"));
  assert(nums.includes("47¹"));
});

Deno.test("parseStatuteXml — preserves chapter context via <peatykk>", () => {
  const sections = parseStatuteXml(MINIMAL_RT_XML);
  const s47 = sections.find((s) => s.num === "47")!;
  assertEquals(s47.chapter, "8");
  assertStringIncludes(s47.heading, "Menetlustähtaja ennistamine");
  const s1 = sections.find((s) => s.num === "1")!;
  assertEquals(s1.chapter, "1");
});

Deno.test("parseStatuteXml — joins multiple <loige> with kuvatavNr markers", () => {
  const sections = parseStatuteXml(MINIMAL_RT_XML);
  const s2 = sections.find((s) => s.num === "2")!;
  assertStringIncludes(s2.text, "(1) Esimene lõige.");
  assertStringIncludes(s2.text, "(2) Teine lõige.");
});

Deno.test("parseStatuteXml — handles ylaIndeks (superscript) section numbers", () => {
  const sections = parseStatuteXml(MINIMAL_RT_XML);
  const s47a = sections.find((s) => s.num === "47¹")!;
  assert(s47a, "should find § 47¹");
  assertEquals(s47a.chapter, "8");
  assertStringIncludes(s47a.heading, "Lisanõuded");
});

Deno.test("parseStatuteXml — does NOT include num/heading inside text body", () => {
  const sections = parseStatuteXml(MINIMAL_RT_XML);
  const s1 = sections.find((s) => s.num === "1")!;
  assert(
    !s1.text.includes("Seaduse ülesanne"),
    `text must not include heading; got: ${s1.text}`,
  );
  assert(
    !s1.text.startsWith("1"),
    `text must not start with section number; got: ${s1.text.slice(0, 40)}`,
  );
});

Deno.test("parseStatuteXml — flat structure (no chapters) still produces sections", () => {
  // Some RT acts (rare) have <paragrahv> as direct children of <oigusakt>
  // body, outside any <peatykk>. Make sure these still parse.
  const flat = `<?xml version="1.0"?>
<oigusakt>
  <metaandmed><lyhend>X</lyhend></metaandmed>
  <paragrahv id="p1">
    <paragrahvNr>1</paragrahvNr>
    <paragrahvPealkiri>Title</paragrahvPealkiri>
    <loige id="lg1"><sisuTekst><tavatekst>Body text here.</tavatekst></sisuTekst></loige>
  </paragrahv>
</oigusakt>`;
  const sections = parseStatuteXml(flat);
  assertEquals(sections.length, 1);
  assertEquals(sections[0].chapter, undefined);
  assertEquals(sections[0].num, "1");
});

Deno.test("parseStatuteXml — skips paragrahv with no/empty body", () => {
  // A § that exists only as a placeholder (e.g. "[kehtetu]" with no
  // tavatekst) should be skipped — we can't embed an empty string.
  const xml = `<?xml version="1.0"?>
<oigusakt>
  <metaandmed><lyhend>X</lyhend></metaandmed>
  <paragrahv><paragrahvNr>1</paragrahvNr><paragrahvPealkiri>x</paragrahvPealkiri></paragrahv>
  <paragrahv><paragrahvNr>2</paragrahvNr>
    <loige><sisuTekst><tavatekst>real body.</tavatekst></sisuTekst></loige>
  </paragrahv>
</oigusakt>`;
  const sections = parseStatuteXml(xml);
  assertEquals(sections.length, 1);
  assertEquals(sections[0].num, "2");
});

Deno.test("parseStatuteXml — skips paragrahv whose <paragrahvNr> is not numeric", () => {
  // RT occasionally emits placeholder paragrahv with non-numeric markers.
  const xml = `<?xml version="1.0"?>
<oigusakt>
  <paragrahv><paragrahvNr>kumottu</paragrahvNr>
    <loige><sisuTekst><tavatekst>some body to bypass min-length.</tavatekst></sisuTekst></loige>
  </paragrahv>
  <paragrahv><paragrahvNr>5</paragrahvNr>
    <loige><sisuTekst><tavatekst>real body that is long enough.</tavatekst></sisuTekst></loige>
  </paragrahv>
</oigusakt>`;
  const sections = parseStatuteXml(xml);
  assertEquals(sections.length, 1);
  assertEquals(sections[0].num, "5");
});

// ── Seed correctness ────────────────────────────────────────────────────────

Deno.test("seed_jobs.sql — exactly 37 RT statute jobs", async () => {
  const sql = await Deno.readTextFile(new URL("../seed_jobs.sql", import.meta.url));
  // Count INSERT VALUES rows — each starts with "('rt',"
  const matches = sql.match(/^\s*\('rt',/gm) ?? [];
  assertEquals(matches.length, 37, "seed must contain 37 RT statute rows");
});

Deno.test("seed_jobs.sql — uses correct RT abbreviations (PankrS not PankS, PKS not PerekS)", async () => {
  const sql = await Deno.readTextFile(new URL("../seed_jobs.sql", import.meta.url));
  // The spec used PankS and PerekS but those DO NOT redirect on RT.
  // We use PankrS + PKS (both verified via curl 2026-05-14).
  assertStringIncludes(sql, "'PankrS'");
  assertStringIncludes(sql, "'PKS'");
  // Make sure the broken forms haven't crept back in as source_ids
  // (they may appear in act_abbrev/act_name overrides, which is fine).
  assert(
    !/^\s*\('rt',\s*'PankS',/m.test(sql),
    "PankS as source_id is wrong (RT 404s on it) — use PankrS",
  );
  assert(
    !/^\s*\('rt',\s*'PerekS',/m.test(sql),
    "PerekS as source_id is wrong (RT 404s on it) — use PKS",
  );
});

Deno.test("seed_jobs.sql — has ON CONFLICT for idempotency", async () => {
  const sql = await Deno.readTextFile(new URL("../seed_jobs.sql", import.meta.url));
  assertStringIncludes(sql, "ON CONFLICT (source, source_id, target_table) DO NOTHING");
});
