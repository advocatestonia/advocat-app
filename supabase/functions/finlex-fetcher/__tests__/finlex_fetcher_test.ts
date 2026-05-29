// Deno tests for finlex-fetcher edge function.
//
// Pure helpers live in ../parser.ts and are imported directly (real ESM, real
// types). Wire-format/contract assertions are still text-source tests against
// index.ts because we don't want to boot the full serve() handler in unit
// tests.
//
// Run from supabase/functions/finlex-fetcher/ with:
//   deno test --allow-env --allow-read

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  aliasVariants,
  parseStatuteXml,
  sectionLabel,
} from "../parser.ts";

const indexSrc = await Deno.readTextFile(new URL("../index.ts", import.meta.url));

// ── Wire format / contract tests ────────────────────────────────────────────

Deno.test("index.ts — POST body shape (worker_id + max_jobs + kind)", () => {
  for (const f of ["worker_id", "max_jobs", "kind"]) {
    assertStringIncludes(
      indexSrc,
      `body.${f}`,
      `must read body.${f}`,
    );
  }
});

Deno.test("index.ts — CRON_SECRET auth (x-cron-secret OR Bearer)", () => {
  assertStringIncludes(indexSrc, "CRON_SECRET");
  // Project convention: x-cron-secret header (sister fetchers use this)
  assertStringIncludes(indexSrc, 'x-cron-secret');
  // Spec also allows Authorization: Bearer. Both header + bearer paths are
  // compared in constant time (timing-oracle fix) — assert the gate uses the
  // constant-time helper rather than a plain `!==`.
  assertStringIncludes(indexSrc, "timingSafeEqualStr(bearer, CRON_SECRET)");
  assertStringIncludes(indexSrc, "timingSafeEqualStr(headerSecret, CRON_SECRET)");
});

Deno.test("index.ts — idempotent insert (delete-then-insert per act_slug)", () => {
  // We rely on delete-then-insert because law_chunks_v2 has no row-level
  // unique constraint on (act_slug, section). Lock that strategy in tests
  // so future refactors don't accidentally duplicate rows.
  assertStringIncludes(
    indexSrc,
    'from("law_chunks_v2")\n    .delete()',
  );
  assertStringIncludes(
    indexSrc,
    'from("statute_aliases")\n    .delete()',
  );
});

Deno.test("index.ts — Finlex base URL + both alkup + consolidated paths", () => {
  // Licence posture (2026-05-15 update):
  //   • alkup (statute, CC BY 4.0)          — default, full display
  //   • ajantasa (statute-consolidated, CC BY-NC 4.0) — opt-in via
  //     payload.redaktsioon='ajantasa', tagged snippet_only at ingest.
  // Both paths must be present. Per Option B from
  // business/legal/finlex_licensing_decision_2026-05-14.md, the consolidated
  // pass is now allowed because we cap downstream display at 200 chars +
  // link-out (legal_lookup.ts LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS).
  assertStringIncludes(indexSrc, "opendata.finlex.fi/finlex/avoindata/v1");
  assertStringIncludes(indexSrc, "act/statute/list");
  assertStringIncludes(indexSrc, "act/statute-consolidated");
});

Deno.test("index.ts — User-Agent header required by Finlex API", () => {
  assertStringIncludes(indexSrc, '"User-Agent": USER_AGENT');
  assertStringIncludes(indexSrc, "AdvocatBot");
});

Deno.test("index.ts — rate limit 1 req/sec/worker", () => {
  const m = indexSrc.match(/REQ_INTERVAL_MS\s*=\s*(\d+)/);
  assert(m, "REQ_INTERVAL_MS constant must exist");
  const ms = parseInt(m![1], 10);
  assert(ms >= 1000, `REQ_INTERVAL_MS must be >= 1000ms, got ${ms}`);
});

Deno.test("index.ts — case_chunks blocked path lands in 'failed' with sticky error", () => {
  // Schema check constraint only allows {queued, fetching, chunking,
  // embedding, done, failed} — there is no 'blocked' state. Case jobs go
  // to 'failed' with a recognisable last_error so a follow-up agent can
  // re-queue them after wiring the headless-browser fetcher.
  assertStringIncludes(indexSrc, "CASE_FETCH_BLOCKED");
  assertStringIncludes(indexSrc, "Finlex AKN-LD3 judgment endpoints return 404");
  assertStringIncludes(indexSrc, "processCaseJob");
});

Deno.test("index.ts — lease guard: only takes status='queued' rows", () => {
  // Lost-update guard against parallel workers
  assertStringIncludes(indexSrc, '.eq("status", "queued")');
});

// ── Citation format tests ───────────────────────────────────────────────────

Deno.test("sectionLabel — chapter-less acts: `ACT N §`", () => {
  assertEquals(sectionLabel("HOL", "114"), "HOL 114 §");
  assertEquals(sectionLabel("UlkL", "168"), "UlkL 168 §");
});

Deno.test("sectionLabel — chapter-structured acts: `ACT CH:N §`", () => {
  // RL 21:1 §  = Rikoslaki chapter 21 section 1 (tappo / manslaughter)
  // RL 21:2 §  = murha
  assertEquals(sectionLabel("RL", "1", "21"), "RL 21:1 §");
  assertEquals(sectionLabel("RL", "2", "21"), "RL 21:2 §");
  assertEquals(sectionLabel("OK", "1", "4"), "OK 4:1 §");
});

Deno.test("sectionLabel — never produces `§ N ACT` reversed form", () => {
  // Load-bearing assertion for citation correctness. If this test fails,
  // downstream citation grounder will reject every FI citation.
  const cases: Array<[string, string, string | undefined]> = [
    ["HOL", "114", undefined],
    ["RL", "1", "21"],
    ["TLS", "32", undefined],
  ];
  for (const [abbrev, num, chapter] of cases) {
    const label = sectionLabel(abbrev, num, chapter);
    assert(
      !label.startsWith("§"),
      `label must NOT start with §; got "${label}"`,
    );
    assert(
      label.endsWith("§"),
      `label MUST end with §; got "${label}"`,
    );
  }
});

Deno.test("aliasVariants — chapter-less: 6 variants, covers common typos", () => {
  const meta = {
    act_slug: "fi-hol",
    act_abbrev: "HOL",
    act_full_name: "Hallintolaki",
    act_number: "434/2003",
    lang: "fi",
    source_url: "x",
  };
  const variants = aliasVariants(meta, "114");
  assertEquals(variants.length, 6);
  const aliases = variants.map((v) => v.alias);
  assert(aliases.includes("HOL 114 §"));
  assert(aliases.includes("Hallintolaki 114 §"));
  assert(aliases.includes("HOL §114"));
  assert(aliases.includes("hallintolaki 114 §"));
  assert(aliases.includes("hol 114 §"));
  assert(aliases.includes("§ 114 HOL"));
});

Deno.test("aliasVariants — chapter-structured: 9 variants including section-only fallback", () => {
  const meta = {
    act_slug: "fi-rl",
    act_abbrev: "RL",
    act_full_name: "Rikoslaki",
    act_number: "39/1889",
    lang: "fi",
    source_url: "x",
  };
  const variants = aliasVariants(meta, "1", "21");
  assertEquals(variants.length, 9);
  const aliases = variants.map((v) => v.alias);
  // Chapter:section forms (the primary)
  assert(aliases.includes("RL 21:1 §"));
  assert(aliases.includes("Rikoslaki 21:1 §"));
  assert(aliases.includes("§ 21:1 RL"));
  // Section-only fallbacks (user forgot the chapter prefix)
  assert(aliases.includes("RL 1 §"));
  assert(aliases.includes("Rikoslaki 1 §"));
  assert(aliases.includes("rl 1 §"));
});

Deno.test("aliasVariants — pattern_kind respects DB check constraint", () => {
  // statute_aliases.pattern_kind only accepts {'exact','regex','common_misspelling'}.
  // The reversed `§ N ACT` form is the FI common misspelling we tolerate.
  const meta = {
    act_slug: "fi-hol",
    act_abbrev: "HOL",
    act_full_name: "Hallintolaki",
    act_number: "434/2003",
    lang: "fi",
    source_url: "x",
  };
  const variants = aliasVariants(meta, "1");
  for (const v of variants) {
    assert(
      ["exact", "regex", "common_misspelling"].includes(v.pattern_kind),
      `pattern_kind "${v.pattern_kind}" violates statute_aliases check constraint`,
    );
  }
  // Canonical variants are 'exact'; reversed is 'common_misspelling'
  const reversed = variants.find((v) => v.alias === "§ 1 HOL");
  assertEquals(reversed?.pattern_kind, "common_misspelling");
});

// ── Parser tests — exercise parseStatuteXml against a minimal AKN fragment ──

const MINIMAL_AKN = `
<akomaNtoso>
  <act>
    <body>
      <chapter eId="chp_1">
        <num>1 luku</num>
        <heading>Yleiset säännökset</heading>
        <section eId="chp_1__sec_1">
          <num>1 §</num>
          <heading>Soveltamisala</heading>
          <subsection>
            <content>
              <p>Tätä lakia sovelletaan hallintoasian käsittelyyn.</p>
            </content>
          </subsection>
        </section>
        <section eId="chp_1__sec_2">
          <num>2 §</num>
          <heading>Lain tarkoitus</heading>
          <subsection>
            <content>
              <p>Lain tarkoituksena on toteuttaa hyvää hallintoa.</p>
            </content>
          </subsection>
        </section>
      </chapter>
      <chapter eId="chp_8">
        <num>8 luku</num>
        <heading>Menetetyn määräajan palauttaminen</heading>
        <section eId="chp_8__sec_114">
          <num>114 §</num>
          <heading>Hakemus määräajan palauttamiseksi</heading>
          <subsection>
            <content>
              <p>Korkein hallinto-oikeus voi palauttaa menetetyn määräajan.</p>
            </content>
          </subsection>
          <subsection>
            <content>
              <p>Hakemus on tehtävä 30 päivän kuluessa esteen lakkaamisesta.</p>
            </content>
          </subsection>
        </section>
      </chapter>
    </body>
  </act>
</akomaNtoso>`;

Deno.test("parseStatuteXml — extracts every <section> with num + body", () => {
  const sections = parseStatuteXml(MINIMAL_AKN);
  assertEquals(sections.length, 3);
  assertEquals(sections.map((s) => s.num).sort(), ["1", "114", "2"]);
});

Deno.test("parseStatuteXml — preserves chapter context", () => {
  const sections = parseStatuteXml(MINIMAL_AKN);
  const s114 = sections.find((s) => s.num === "114")!;
  assertEquals(s114.chapter, "8");
  assertStringIncludes(s114.heading, "Hakemus määräajan palauttamiseksi");
});

Deno.test("parseStatuteXml — joins multiple <subsection>/<p> into one body", () => {
  const sections = parseStatuteXml(MINIMAL_AKN);
  const s114 = sections.find((s) => s.num === "114")!;
  assertStringIncludes(s114.text, "Korkein hallinto-oikeus");
  assertStringIncludes(s114.text, "30 päivän kuluessa");
});

Deno.test("parseStatuteXml — does NOT include num/heading inside text", () => {
  const sections = parseStatuteXml(MINIMAL_AKN);
  const s1 = sections.find((s) => s.num === "1")!;
  assert(
    !s1.text.startsWith("1 §"),
    `section text must not start with the section num; got: ${s1.text.slice(0, 80)}`,
  );
});

Deno.test("parseStatuteXml — handles act with no chapters (HOL-like)", () => {
  const flatAkn = `
<akomaNtoso><act><body>
  <section><num>1 §</num><heading>X</heading>
    <subsection><content><p>Body of one.</p></content></subsection>
  </section>
  <section><num>2 §</num><heading>Y</heading>
    <subsection><content><p>Body of two.</p></content></subsection>
  </section>
</body></act></akomaNtoso>`;
  const sections = parseStatuteXml(flatAkn);
  assertEquals(sections.length, 2);
  for (const s of sections) {
    assertEquals(s.chapter, undefined);
  }
});

Deno.test("parseStatuteXml — gracefully skips section with no <num>", () => {
  // Section with no <num> is skipped; well-formed neighbour is kept. We use
  // a body >= 5 chars on the kept section to clear the min-length filter
  // (which is a separate guarantee tested below).
  const messy = `
<akomaNtoso><act><body>
  <section><heading>no num here</heading><subsection><content><p>orphan body</p></content></subsection></section>
  <section><num>5 §</num><subsection><content><p>real body text</p></content></subsection></section>
</body></act></akomaNtoso>`;
  const sections = parseStatuteXml(messy);
  assertEquals(sections.length, 1);
  assertEquals(sections[0].num, "5");
});

Deno.test("parseStatuteXml — handles section letter suffix (114 a §)", () => {
  const akn = `
<akomaNtoso><act><body>
  <section><num>114 a §</num><heading>X</heading>
    <subsection><content><p>letter suffix.</p></content></subsection>
  </section>
</body></act></akomaNtoso>`;
  const sections = parseStatuteXml(akn);
  assertEquals(sections.length, 1);
  // Letter is preserved, lowercased
  assertEquals(sections[0].num, "114 a");
});

Deno.test("parseStatuteXml — minimum body length: skips empty sections", () => {
  // A section that exists only to be marked "kumottu" (repealed) should
  // produce a usable chunk if it has explanatory text, but a 0-char body
  // should be dropped (we can't embed an empty string).
  const akn = `
<akomaNtoso><act><body>
  <section><num>1 §</num><heading>x</heading></section>
  <section><num>2 §</num><heading>y</heading>
    <subsection><content><p>has real body.</p></content></subsection>
  </section>
</body></act></akomaNtoso>`;
  const sections = parseStatuteXml(akn);
  assertEquals(sections.length, 1);
  assertEquals(sections[0].num, "2");
});

// ── Option B (2026-05-15) — ajantasa pass + license tagging ─────────────────
// Per business/legal/finlex_licensing_decision_2026-05-14.md, we ingest
// consolidated/ajantasa text from /act/statute-consolidated/{year}/{num}/fin@
// and tag every inserted row with license='CC-BY-NC-4.0' +
// display_policy='snippet_only'. Original-text (alkup) ingestion remains
// the default for backward compatibility — payload must opt in via
// "redaktsioon": "ajantasa".

Deno.test("index.ts — ajantasa pass uses statute-consolidated URI path", () => {
  // The consolidated ingestion path is the licence-tagged one. It MUST
  // appear in source — otherwise the ajantasa work is unreachable.
  assertStringIncludes(indexSrc, "statute-consolidated");
});

Deno.test("index.ts — ajantasa payload opts in via redaktsioon=ajantasa", () => {
  // Payload contract: { redaktsioon: 'ajantasa' } switches the fetcher to
  // the consolidated pass. Without this key the fetcher stays on alkup
  // (preserves all existing seed_jobs.sql behaviour).
  assertStringIncludes(indexSrc, "ajantasa");
  assertStringIncludes(indexSrc, "redaktsioon");
});

Deno.test("index.ts — ajantasa chunks tagged CC-BY-NC-4.0 / snippet_only", () => {
  // The licence/policy tagging is what the entire Option B decision pivots
  // on. If a future refactor drops these literals, snippet enforcement in
  // legal_lookup silently degrades to full-quote behaviour.
  assertStringIncludes(indexSrc, "CC-BY-NC-4.0");
  assertStringIncludes(indexSrc, "snippet_only");
});

Deno.test("index.ts — source_id accepts YYYY/N AND YYYY/N:ajantasa", () => {
  // The ajantasa seed (20260515040000_seed_ajantasa_phase1.sql) uses
  // source_id="YYYY/N:ajantasa" so the UNIQUE constraint on
  // (source, source_id, target_table) does NOT collide with the matching
  // alkup row. The fetcher MUST accept both shapes.
  assertStringIncludes(indexSrc, ":ajantasa");
  // Regex source matches both forms — anchor on the literal pattern so a
  // future refactor that drops the suffix tolerance trips this test.
  assert(
    /\/\^\(\\d\{4\}\)\\\/\(\\d\+\)\(\?:\\?:ajantasa\)\??\\?\$\//.test(indexSrc) ||
      indexSrc.includes("(?::ajantasa)?"),
    "expected source_id regex to tolerate optional :ajantasa suffix",
  );
});

Deno.test("index.ts — alkup pass keeps public-domain default (no NC tag)", () => {
  // The licence assignment must be a CONDITIONAL ternary on redaktsioon
  // (not an unconditional CC-BY-NC stamp). We detect the ternary by looking
  // for the structural pattern, then sanity-check that the alkup branch
  // resolves to 'public-domain'.
  //
  // Resilient to formatting — both `?:` operands matched; explicit anchor
  // on the redaktsioon variable so future refactors that keep the gate but
  // rename the local don't silently break the assertion.
  assertStringIncludes(indexSrc, "CC-BY-NC-4.0");
  assertStringIncludes(indexSrc, "public-domain");
  assertStringIncludes(indexSrc, "redaktsioon === \"ajantasa\"");
  // The ternary expression that produces the licence tag must be visible:
  //   redaktsioon === "ajantasa" ? "CC-BY-NC-4.0" : "public-domain"
  // (whitespace-tolerant via the regex)
  const ternary =
    /redaktsioon\s*===\s*"ajantasa"\s*\?\s*\n?\s*"CC-BY-NC-4\.0"\s*\n?\s*:\s*\n?\s*"public-domain"/;
  assert(
    ternary.test(indexSrc),
    "expected ternary `redaktsioon === 'ajantasa' ? 'CC-BY-NC-4.0' : 'public-domain'`",
  );
});
