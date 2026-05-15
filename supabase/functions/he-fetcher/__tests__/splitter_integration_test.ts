// Integration test — exercises the splitter against a REAL Finlex HE PDF
// (HE 72/2002 vp, ~143 pages). Run manually:
//
//   deno test --allow-net --allow-read --allow-env --no-check \
//     supabase/functions/he-fetcher/__tests__/splitter_integration_test.ts
//
// Skipped by the default CI run because it depends on Finlex availability;
// useful when debugging the splitter without an Anthropic key in scope.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { PDFDocument } from "https://esm.sh/pdf-lib@1.17.1";
import {
  downloadAndSplit,
  downloadAndStream,
  PAGES_PER_SEGMENT,
} from "../pdf_splitter.ts";

const UA = "AdvocatTravauxFetcher/1.0 (+https://advocat.ee; legal-aid AI)";
// HE 72/2002 vp Hallintolaki — 143 pages — perfect canary for the split path.
const HE_72_2002_PDF =
  "https://www.finlex.fi/api/media/government-proposal/715521/mainPdf/main.pdf";

Deno.test({
  name: "splitter-integration — HE 72/2002 vp splits into ceil(pages/cap) segments",
  ignore: Deno.env.get("RUN_LIVE_PDF_TESTS") !== "1",
  fn: async () => {
    const out = await downloadAndSplit(HE_72_2002_PDF, UA, 60_000);
    // 143 / 50 = 3 segments (was 2 with old 90-page cap).
    assert(out.total_pages > 100, `expected >100 pages, got ${out.total_pages}`);
    assertEquals(out.segments.length, Math.ceil(out.total_pages / PAGES_PER_SEGMENT));
    // Verify each segment is a valid PDF and the page math is right.
    for (const seg of out.segments) {
      const sub = await PDFDocument.load(seg.bytes, { ignoreEncryption: true });
      assertEquals(sub.getPageCount(), seg.end_page - seg.start_page + 1);
    }
  },
});

Deno.test({
  name: "splitter-integration — streaming HE 72/2002 vp yields ceil(pages/cap)",
  ignore: Deno.env.get("RUN_LIVE_PDF_TESTS") !== "1",
  fn: async () => {
    // Fix #89 round 3 — verify the streaming path used by the hot path in
    // index.ts. Each yielded segment is a valid sub-PDF and total count
    // matches the plan.
    const { plan, iterator } = await downloadAndStream(
      HE_72_2002_PDF,
      UA,
      60_000,
    );
    assert(plan.total_pages > 100);
    let count = 0;
    let totalSubPages = 0;
    for await (const seg of iterator) {
      count++;
      const sub = await PDFDocument.load(seg.bytes, { ignoreEncryption: true });
      const subPages = sub.getPageCount();
      assertEquals(subPages, seg.end_page - seg.start_page + 1);
      totalSubPages += subPages;
    }
    assertEquals(count, plan.segment_count);
    assertEquals(totalSubPages, plan.total_pages);
  },
});
