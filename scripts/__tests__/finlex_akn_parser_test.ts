// Unit tests for finlex_akn_parser.ts — Akoma Ntoso → ParsedSection pipeline.
// -----------------------------------------------------------------------------
// Phase 2 Pkg 1 (Finland corpus, 2026-05-11). These tests pin the parser's
// behaviour against synthetic Akoma Ntoso fragments that mirror the real
// shapes Finlex serves under /akn/fi/act/statute/{year}/{number}/fin@.
//
// We do NOT hit the network — the parser is pure regex over a string,
// and the cost of testing it offline is zero.
//
// Run with:
//   deno test --allow-read scripts/__tests__/finlex_akn_parser_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildParagraphId,
  decodeEntities,
  findSections,
  leadingInt,
  parseSectionInner,
  stripTags,
} from "../finlex_akn_parser.ts";

// ── FNX-T01 — primitives ─────────────────────────────────────────────────────

Deno.test("FNX-T01 — decodeEntities handles the common XML escapes", () => {
  assertEquals(decodeEntities("a &amp; b"), "a & b");
  assertEquals(decodeEntities("&lt;p&gt;hi&lt;/p&gt;"), "<p>hi</p>");
  assertEquals(decodeEntities("Ker&#228;t"), "Kerät"); // ä as numeric
  assertEquals(decodeEntities("Ker&#xE4;t"), "Kerät"); // ä as hex
  assertEquals(decodeEntities("Sa&apos;d"), "Sa'd");
  assertEquals(decodeEntities("&quot;cite&quot;"), '"cite"');
});

Deno.test("FNX-T02 — stripTags removes XML and collapses whitespace", () => {
  assertEquals(stripTags("<p>Hello   world</p>"), "Hello world");
  assertEquals(
    stripTags("<b>Työ</b><i>sopimus</i>   <span>laki</span>"),
    "Työ sopimus laki",
  );
  assertEquals(stripTags("   "), "");
});

Deno.test("FNX-T03 — leadingInt extracts the first integer or null", () => {
  assertEquals(leadingInt("7 luku"), "7");
  assertEquals(leadingInt("3 §"), "3");
  assertEquals(leadingInt("  42  "), "42");
  assertEquals(leadingInt("luku 7"), null);
  assertEquals(leadingInt(""), null);
});

Deno.test("FNX-T04 — buildParagraphId yields chapter-section or bare section", () => {
  assertEquals(buildParagraphId("7", "3"), "7-3");
  assertEquals(buildParagraphId(null, "26"), "26");
  assertEquals(buildParagraphId("12", "1"), "12-1");
});

// ── FNX-T05 — section-level parser ───────────────────────────────────────────

Deno.test("FNX-T05 — parseSectionInner extracts num + heading + body", () => {
  const inner = `
    <num>3 §</num>
    <heading>Henkilöön liittyvät irtisanomisperusteet</heading>
    <content>
      <p>Työnantaja saa irtisanoa toistaiseksi voimassa olevan työsopimuksen vain asiallisesta ja painavasta syystä.</p>
    </content>
  `;
  const result = parseSectionInner(inner, "7");
  if (!result) throw new Error("Expected non-null parse result");
  assertEquals(result.chapterNum, "7");
  assertEquals(result.sectionNum, "3");
  assertEquals(result.title, "Henkilöön liittyvät irtisanomisperusteet");
  assertStringIncludes(result.body, "asiallisesta ja painavasta syystä");
  assertEquals(result.subsections.length, 0);
});

Deno.test("FNX-T06 — parseSectionInner returns null without <num>", () => {
  const inner = `<content><p>body without num</p></content>`;
  assertEquals(parseSectionInner(inner, "7"), null);
});

Deno.test("FNX-T07 — parseSectionInner returns null with empty body", () => {
  const inner = `<num>3 §</num><heading>Tyhjä</heading>`;
  assertEquals(parseSectionInner(inner, "7"), null);
});

Deno.test(
  "FNX-T08 — parseSectionInner extracts subsections with their num attribute",
  () => {
    const inner = `
    <num>54 §</num>
    <heading>Tiedoksiannon tavat</heading>
    <content>
      <p>Viranomaisen on annettava päätös tiedoksi asianosaiselle.</p>
    </content>
    <subsection num="1">
      <p>Todisteellinen tiedoksianto.</p>
    </subsection>
    <subsection num="2">
      <p>Yleistiedoksianto.</p>
    </subsection>
  `;
    const result = parseSectionInner(inner, null);
    if (!result) throw new Error("Expected non-null result");
    assertEquals(result.chapterNum, null);
    assertEquals(result.sectionNum, "54");
    assertEquals(result.subsections.length, 2);
    assertEquals(result.subsections[0].id, "(1)");
    assertStringIncludes(result.subsections[0].text, "Todisteellinen");
    assertEquals(result.subsections[1].id, "(2)");
    // Subsection bodies are also concatenated into the main body so the
    // embedding gets the full legal weight.
    assertStringIncludes(result.body, "Todisteellinen tiedoksianto.");
    assertStringIncludes(result.body, "Yleistiedoksianto.");
  },
);

Deno.test(
  "FNX-T09 — parseSectionInner handles multi-paragraph <content> blocks",
  () => {
    const inner = `
    <num>40 §</num>
    <content>
      <p>Ensimmäinen kappale.</p>
      <p>Toinen kappale.</p>
      <p>Kolmas kappale.</p>
    </content>
  `;
    const result = parseSectionInner(inner, "5");
    if (!result) throw new Error("Expected non-null result");
    // Joined with blank lines so the order is preserved and visible.
    assertStringIncludes(result.body, "Ensimmäinen kappale.");
    assertStringIncludes(result.body, "Toinen kappale.");
    assertStringIncludes(result.body, "Kolmas kappale.");
  },
);

// ── FNX-T10 — full-tree walker ───────────────────────────────────────────────

Deno.test(
  "FNX-T10 — findSections walks chapters and pairs each section with its chapter num",
  () => {
    // Synthetic excerpt mirroring TSL's chapter structure.
    const xml = `
    <akomaNtoso>
      <act>
        <body>
          <chapter eId="chp_7">
            <num>7 luku</num>
            <heading>Työsopimuksen päättämisperusteet</heading>
            <section eId="chp_7__sec_1">
              <num>1 §</num>
              <heading>Yleinen säännös</heading>
              <content><p>Työsopimuksen päättäminen.</p></content>
            </section>
            <section eId="chp_7__sec_3">
              <num>3 §</num>
              <heading>Henkilöön liittyvät irtisanomisperusteet</heading>
              <content><p>Asiallisesta ja painavasta syystä.</p></content>
            </section>
          </chapter>
          <chapter eId="chp_12">
            <num>12 luku</num>
            <section>
              <num>1 §</num>
              <content><p>Erityissäännös.</p></content>
            </section>
          </chapter>
        </body>
      </act>
    </akomaNtoso>
  `;
    const sections = findSections(xml);
    assertEquals(sections.length, 3);
    // Section 7-1
    assertEquals(sections[0].chapterNum, "7");
    assertEquals(sections[0].sectionNum, "1");
    assertEquals(sections[0].title, "Yleinen säännös");
    // Section 7-3 — most-cited TSL paragraph
    assertEquals(sections[1].chapterNum, "7");
    assertEquals(sections[1].sectionNum, "3");
    assertStringIncludes(sections[1].body, "Asiallisesta ja painavasta");
    // Section 12-1 — across-chapter walk works
    assertEquals(sections[2].chapterNum, "12");
    assertEquals(sections[2].sectionNum, "1");
  },
);

Deno.test(
  "FNX-T11 — findSections handles chapter-less (older) statutes",
  () => {
    // Some pre-2000 Finnish acts use bare <section> directly under <body>
    // with no <chapter> wrapper. The parser must yield chapterNum=null
    // for those and the corpus paragraph ID becomes just the section.
    const xml = `
    <akomaNtoso>
      <act>
        <body>
          <section><num>1 §</num><content><p>Ensimmäinen pykälä.</p></content></section>
          <section><num>26 §</num>
            <heading>Tulkitseminen ja kääntäminen</heading>
            <content><p>Viranomaisen on järjestettävä tulkitseminen.</p></content>
          </section>
        </body>
      </act>
    </akomaNtoso>
  `;
    const sections = findSections(xml);
    assertEquals(sections.length, 2);
    assertEquals(sections[0].chapterNum, null);
    assertEquals(sections[0].sectionNum, "1");
    assertEquals(sections[1].chapterNum, null);
    assertEquals(sections[1].sectionNum, "26");
    assertEquals(sections[1].title, "Tulkitseminen ja kääntäminen");
    // Compound id is just the section number when there's no chapter
    assertEquals(buildParagraphId(sections[1].chapterNum, sections[1].sectionNum), "26");
  },
);

Deno.test(
  "FNX-T12 — findSections skips malformed sections without throwing",
  () => {
    // Section without <num> — must be skipped, not crash the walker.
    // Section with empty body — must be skipped.
    // Section with valid content — must be emitted.
    const xml = `
    <akomaNtoso><act><body>
      <chapter>
        <num>1 luku</num>
        <section><heading>Otsikko ilman num</heading><content><p>body</p></content></section>
        <section><num>2 §</num></section>
        <section><num>3 §</num><content><p>Validi pykälä.</p></content></section>
      </chapter>
    </body></act></akomaNtoso>
  `;
    const sections = findSections(xml);
    assertEquals(sections.length, 1);
    assertEquals(sections[0].sectionNum, "3");
    assertStringIncludes(sections[0].body, "Validi pykälä.");
  },
);

Deno.test(
  "FNX-T13 — XML entities in body text are decoded",
  () => {
    const inner = `
      <num>5 §</num>
      <content><p>Ker&#228;t&#228;&#228;n tietoja &amp; tarkistetaan.</p></content>
    `;
    const result = parseSectionInner(inner, null);
    if (!result) throw new Error("Expected non-null result");
    assertStringIncludes(result.body, "Kerätään");
    assertStringIncludes(result.body, "&");
  },
);

// ── FNX-T14 — end-to-end sanity check with TSL 7-3 reference shape ───────────

Deno.test(
  "FNX-T14 — end-to-end: TSL 7-3 reference shape parses to expected (7, 3, body)",
  () => {
    // This is the SINGLE most-cited Finnish employment-law paragraph
    // (equivalent of Estonian TLS § 88). The design doc §10 prints the
    // expected output shape verbatim; we assert against the same.
    const xml = `
    <akomaNtoso><act><body>
      <chapter eId="chp_7">
        <num>7 luku</num>
        <heading>Työsopimuksen päättämisperusteet</heading>
        <section eId="chp_7__sec_3">
          <num>3 §</num>
          <heading>Henkilöön liittyvät irtisanomisperusteet</heading>
          <content>
            <p>Työnantaja saa irtisanoa toistaiseksi voimassa olevan työsopimuksen vain asiallisesta ja painavasta syystä.</p>
          </content>
        </section>
      </chapter>
    </body></act></akomaNtoso>
    `;
    const sections = findSections(xml);
    assertEquals(sections.length, 1);
    const s = sections[0];
    assertEquals(s.chapterNum, "7");
    assertEquals(s.sectionNum, "3");
    assertEquals(s.title, "Henkilöön liittyvät irtisanomisperusteet");
    assertStringIncludes(s.body, "asiallisesta ja painavasta syystä");
    // Corpus paragraph id matches the marker-friendly form `[[ref:fi-tsl:7-3]]`
    assertEquals(buildParagraphId(s.chapterNum, s.sectionNum), "7-3");
  },
);
