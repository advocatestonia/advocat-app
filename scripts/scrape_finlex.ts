#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net --allow-env
/**
 * scrape_finlex.ts
 *
 * Scrapes Finnish statutes from the Finlex open-data API (launched
 * 27 February 2026) and writes structured JSON files compatible with
 * `ingest_law_corpus.ts`.
 *
 * Source: https://opendata.finlex.fi/finlex/avoindata/v1
 * Licence: CC BY 4.0 for original statutes + amendments (NOT the
 * "ajantasainen" consolidated text, which is CC-BY-NC and incompatible
 * with commercial use — see docs/legal/corpus_licences.md).
 *
 * Output files: assets/legal/finland/<act_slug>.json
 * Schema mirrors the existing Estonian corpus + the FI shells that were
 * hand-curated for the Sulga case (e.g. assets/legal/finland/hallintolaki.json).
 *
 * Slug convention: `fi-` prefix to avoid PK collisions with Estonian acts
 * sharing an abbreviation (e.g. Estonian Töölepingu seadus and Finnish
 * Työsopimuslaki both abbreviate as TLS/TSL). Decision pinned in the
 * Phase 1 design doc §6.
 *
 * Paragraph IDs: `<chapter>-<section>` (e.g. "7-3" for "7 luku 3 §").
 * For acts without chapter structure, falls back to "<section>" (e.g. "26").
 *
 * Usage:
 *   deno run --allow-read --allow-write --allow-net --allow-env \
 *     scripts/scrape_finlex.ts
 *
 *   # Specific acts only:
 *   deno run ... scripts/scrape_finlex.ts --acts=fi-tsl,fi-ul
 *
 *   # Dry-run (no file writes; print parsed counts):
 *   deno run ... scripts/scrape_finlex.ts --dry-run
 *
 * Environment:
 *   FINLEX_USER_AGENT  Custom UA string (default: advocat.ee/1.0
 *                      <support@advocat.ee>). Required by Finlex ToS.
 *   FINLEX_RATE_MS     Min ms between requests (default 1100).
 *   OUTPUT_DIR         Override output dir (default
 *                      assets/legal/finland).
 */

// ── Config ───────────────────────────────────────────────────────────────────

const FINLEX_BASE = "https://opendata.finlex.fi/finlex/avoindata/v1";
const USER_AGENT = Deno.env.get("FINLEX_USER_AGENT") ??
  "advocat.ee/1.0 <support@advocat.ee>";
const RATE_LIMIT_MS = parseInt(Deno.env.get("FINLEX_RATE_MS") ?? "1100", 10);
const OUTPUT_DIR = Deno.env.get("OUTPUT_DIR") ?? "assets/legal/finland";

const ARGS = new Map<string, string>();
for (const arg of Deno.args) {
  if (arg.startsWith("--")) {
    const [k, v] = arg.slice(2).split("=", 2);
    ARGS.set(k, v ?? "true");
  }
}
const DRY_RUN = ARGS.get("dry-run") === "true";
const ACTS_FILTER: Set<string> | null = ARGS.has("acts")
  ? new Set(ARGS.get("acts")!.split(",").map((s) => s.trim()).filter(Boolean))
  : null;

// ── Phase 1 priority acts ────────────────────────────────────────────────────

/** The 11 Phase-1 priority Finnish acts. Each row: {act_slug, year, number,
 *  name, name_en}. Slugs use `fi-` prefix per design doc §6. */
interface ActMeta {
  slug: string;
  year: number;
  number: number;
  name: string;
  name_en: string;
}

const PHASE_1_ACTS: ActMeta[] = [
  { slug: "fi-tsl", year: 2001, number: 55,
    name: "Työsopimuslaki", name_en: "Employment Contracts Act" },
  { slug: "fi-ul", year: 2004, number: 301,
    name: "Ulkomaalaislaki", name_en: "Aliens Act" },
  { slug: "fi-hl", year: 2003, number: 434,
    name: "Hallintolaki", name_en: "Administrative Procedure Act" },
  { slug: "fi-loha", year: 2019, number: 808,
    name: "Laki oikeudenkäynnistä hallintoasioissa",
    name_en: "Administrative Court Procedure Act" },
  { slug: "fi-al", year: 1929, number: 234,
    name: "Avioliittolaki", name_en: "Marriage Act" },
  { slug: "fi-lhl", year: 1983, number: 361,
    name: "Laki lapsen huollosta ja tapaamisoikeudesta",
    name_en: "Child Custody Act" },
  { slug: "fi-rl", year: 1889, number: 39,
    name: "Rikoslaki", name_en: "Criminal Code" },
  { slug: "fi-ksl", year: 1978, number: 38,
    name: "Kuluttajansuojalaki", name_en: "Consumer Protection Act" },
  { slug: "fi-vjl", year: 1993, number: 57,
    name: "Velkajärjestelylaki", name_en: "Debt Adjustment Act" },
  { slug: "fi-vkl", year: 1974, number: 412,
    name: "Vahingonkorvauslaki", name_en: "Tort Liability Act" },
  { slug: "fi-ahvl", year: 1995, number: 481,
    name: "Laki asuinhuoneiston vuokrauksesta",
    name_en: "Residential Lease Act" },
];

// ── Output schema (matches existing FI shells + ingest_law_corpus.ts) ────────

interface Section {
  paragraph: string;       // "<chapter>-<section>" or "<section>"
  title?: string;          // section heading if present
  body: string;            // concatenated paragraph text (subsections joined)
  subsections?: Array<{ id: string; text: string }>;
}

interface LawFile {
  act: string;
  name: string;
  name_en?: string;
  source: string;
  fetched_at: string;
  jurisdiction: "FI";
  language: "fi";
  sections: Section[];
}

// ── HTTP with rate limiting + retry on 429 ───────────────────────────────────

let lastRequestAt = 0;

async function rateLimitedFetch(url: string): Promise<Response> {
  const now = Date.now();
  const wait = Math.max(0, lastRequestAt + RATE_LIMIT_MS - now);
  if (wait > 0) {
    await new Promise((r) => setTimeout(r, wait));
  }
  lastRequestAt = Date.now();

  for (let attempt = 0; attempt < 5; attempt++) {
    const resp = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept-Encoding": "gzip",
        // Akoma Ntoso XML is the default; ask for it explicitly so the
        // server doesn't auto-redirect us to the HTML representation.
        "Accept": "application/akn+xml, application/xml, text/xml",
      },
    });

    if (resp.status === 429) {
      const retryAfter = parseInt(resp.headers.get("retry-after") ?? "30", 10);
      console.warn(`  [429] waiting ${retryAfter}s before retry...`);
      await new Promise((r) => setTimeout(r, (retryAfter + 1) * 1000));
      continue;
    }

    if (resp.status >= 500 && resp.status < 600) {
      console.warn(`  [${resp.status}] server error, retry ${attempt + 1}/5`);
      await new Promise((r) => setTimeout(r, 2000 * (attempt + 1)));
      continue;
    }

    return resp;
  }

  throw new Error(`Finlex fetch ${url} — exceeded 5 retries`);
}

// ── Akoma Ntoso XML parser ───────────────────────────────────────────────────
//
// Akoma Ntoso is the international legal-XML standard. Finnish statutes use
// the structure:
//   <akomaNtoso>
//     <act>
//       <body>
//         <chapter eId="chp_7">
//           <num>7 luku</num>
//           <heading>...</heading>
//           <section eId="chp_7__sec_3">
//             <num>3 §</num>
//             <heading>...</heading>
//             <content><p>...</p></content>
//             <subsection num="1">...</subsection>  -- some acts
//           </section>
//         </chapter>
//       </body>
//     </act>
//   </akomaNtoso>
//
// Older acts may omit chapters and use bare <section> elements directly
// under <body>. We handle both shapes.
//
// We use a regex-based extractor rather than a full XML parser because:
//   (a) Deno's std XML parser is heavyweight and ESM-loaded;
//   (b) Akoma Ntoso has well-known tag boundaries;
//   (c) we want graceful skip-on-error per section, which is easier
//       to bolt onto a regex walker than a strict DOM parser.
//
// The parser primitives live in finlex_akn_parser.ts so they can be
// unit-tested without importing this script's top-level fetch/exit
// statements.

import { buildParagraphId, findSections } from "./finlex_akn_parser.ts";

// ── Per-act fetch + transform ────────────────────────────────────────────────

function buildAknUrl(meta: ActMeta): string {
  // /akn/fi/act/statute/{year}/{number}/{LangAndVersion}
  // LangAndVersion: fin@ = Finnish, original (non-consolidated) text
  return `${FINLEX_BASE}/akn/fi/act/statute/${meta.year}/${meta.number}/fin@`;
}

async function scrapeAct(meta: ActMeta): Promise<LawFile> {
  const url = buildAknUrl(meta);
  console.log(`  fetching ${meta.slug} (${meta.name}) ← ${url}`);

  const resp = await rateLimitedFetch(url);
  if (!resp.ok) {
    throw new Error(`Finlex returned ${resp.status} for ${meta.slug}: ${url}`);
  }
  const xml = await resp.text();

  const parsedSections = findSections(xml);
  if (parsedSections.length === 0) {
    throw new Error(
      `No sections parsed for ${meta.slug} — XML shape unexpected? ` +
        `(${xml.length} chars fetched)`,
    );
  }

  const sections: Section[] = parsedSections.map((ps) => {
    return {
      paragraph: buildParagraphId(ps.chapterNum, ps.sectionNum),
      title: ps.title ?? undefined,
      body: ps.body,
      subsections: ps.subsections.length > 0 ? ps.subsections : undefined,
    };
  });

  return {
    act: meta.slug,
    name: `${meta.name} (${meta.number}/${meta.year})`,
    name_en: meta.name_en,
    source: url,
    fetched_at: new Date().toISOString(),
    jurisdiction: "FI",
    language: "fi",
    sections,
  };
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function ensureOutputDir(): Promise<void> {
  if (DRY_RUN) return;
  try {
    await Deno.mkdir(OUTPUT_DIR, { recursive: true });
  } catch (err) {
    if (!(err instanceof Deno.errors.AlreadyExists)) throw err;
  }
}

async function writeActJson(act: LawFile): Promise<void> {
  if (DRY_RUN) return;
  const path = `${OUTPUT_DIR}/${act.act}.json`;
  await Deno.writeTextFile(path, JSON.stringify(act, null, 2) + "\n");
  console.log(`  wrote ${path} (${act.sections.length} sections)`);
}

console.log("Advocat — Finlex scraper");
console.log(`  Base       : ${FINLEX_BASE}`);
console.log(`  Output dir : ${OUTPUT_DIR}`);
console.log(`  Rate limit : 1 req / ${RATE_LIMIT_MS}ms`);
console.log(`  User-Agent : ${USER_AGENT}`);
console.log(`  Dry run    : ${DRY_RUN}`);
if (ACTS_FILTER) {
  console.log(`  Acts       : ${[...ACTS_FILTER].join(", ")}`);
}
console.log();

await ensureOutputDir();

const targets = ACTS_FILTER
  ? PHASE_1_ACTS.filter((a) => ACTS_FILTER.has(a.slug))
  : PHASE_1_ACTS;

if (targets.length === 0) {
  console.error("No acts matched the --acts filter.");
  Deno.exit(1);
}

let totalSections = 0;
const failures: Array<{ slug: string; error: string }> = [];

for (const meta of targets) {
  try {
    const act = await scrapeAct(meta);
    await writeActJson(act);
    totalSections += act.sections.length;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`  FAIL ${meta.slug}: ${msg}`);
    failures.push({ slug: meta.slug, error: msg });
  }
}

console.log();
console.log("═".repeat(50));
console.log(`Scrape complete`);
console.log(`  Acts attempted : ${targets.length}`);
console.log(`  Sections total : ${totalSections}`);
console.log(`  Failures       : ${failures.length}`);
for (const f of failures) {
  console.log(`    - ${f.slug}: ${f.error}`);
}
console.log("═".repeat(50));

if (failures.length > 0) Deno.exit(1);
