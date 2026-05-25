// Deno tests for the image branch of the pdf-parser Edge Function.
// -----------------------------------------------------------------------------
// P0 fix 2026-05-25: pdf-parser previously rejected anything non-PDF at the
// MIME gate. Users snapping a photo of a paper letter got "unsupported" at
// step 1. This test suite pins:
//   * MIME validator accepts image/jpeg, image/png, image/heic, image/heif,
//     image/webp (and the loose image/jpg alias).
//   * Invalid MIMEs are still rejected.
//   * MIME canonicalization: image/jpg → image/jpeg.
//   * normalizeImageMediaType collapses to Anthropic's enum (jpeg|png|webp).
//   * index.ts wires the image branch: skips pdfjs, calls Vision once,
//     reuses the same Sonnet structured-extraction step.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/pdf-parser/__tests__/image_path_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  isImageMime,
  isPdfMime,
  normalizeImageMediaType,
  parseAndValidateBody,
  SUPPORTED_IMAGE_MIME_TYPES,
} from "../helpers.ts";

const UID_A = "11111111-1111-1111-1111-111111111111";

// =============================================================================
// 1. isImageMime / isPdfMime helpers
// =============================================================================

Deno.test("IMGP-T01 — isImageMime accepts every supported MIME", () => {
  for (const m of SUPPORTED_IMAGE_MIME_TYPES) {
    assert(isImageMime(m), `${m} should be accepted`);
    // Case-insensitive.
    assert(isImageMime(m.toUpperCase()), `${m.toUpperCase()} should be accepted`);
    // Whitespace-tolerant.
    assert(isImageMime(`  ${m}  `), `'  ${m}  ' should be accepted`);
  }
});

Deno.test("IMGP-T02 — isImageMime rejects unsupported MIMEs", () => {
  const bad = [
    "application/pdf",
    "image/gif",
    "image/tiff",
    "image/bmp",
    "application/octet-stream",
    "text/html",
    "",
  ];
  for (const m of bad) {
    assertEquals(isImageMime(m), false, `${m} should be rejected`);
  }
});

Deno.test("IMGP-T03 — isPdfMime accepts application/pdf + 'pdf' alias", () => {
  assert(isPdfMime("application/pdf"));
  assert(isPdfMime("APPLICATION/PDF"));
  assert(isPdfMime("pdf"));
  assert(isPdfMime("  application/pdf  "));
  assertEquals(isPdfMime("image/jpeg"), false);
  assertEquals(isPdfMime(""), false);
});

// =============================================================================
// 2. normalizeImageMediaType — Anthropic Vision enum mapping
// =============================================================================

Deno.test("IMGP-T10 — normalizeImageMediaType maps to Anthropic enum", () => {
  // Direct passes.
  assertEquals(normalizeImageMediaType("image/png"), "image/png");
  assertEquals(normalizeImageMediaType("image/webp"), "image/webp");
  // JPEG family.
  assertEquals(normalizeImageMediaType("image/jpeg"), "image/jpeg");
  assertEquals(normalizeImageMediaType("image/jpg"), "image/jpeg");
  // HEIC/HEIF → jpeg (Anthropic's enum doesn't list HEIC; bytes pass
  // through verbatim but media_type label must be one of the supported
  // values, jpeg is the safest choice).
  assertEquals(normalizeImageMediaType("image/heic"), "image/jpeg");
  assertEquals(normalizeImageMediaType("image/heif"), "image/jpeg");
  // Case + whitespace.
  assertEquals(normalizeImageMediaType("IMAGE/PNG"), "image/png");
  assertEquals(normalizeImageMediaType("  image/webp  "), "image/webp");
});

// =============================================================================
// 3. parseAndValidateBody — image MIMEs are now accepted
// =============================================================================

Deno.test("IMGP-T20 — JPEG happy path: case_id present, body validates", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/photo.jpg`,
      case_id: null,
      mime_type: "image/jpeg",
      filename: "photo.jpg",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "image/jpeg");
  assertEquals(r.filename, "photo.jpg");
});

Deno.test("IMGP-T21 — PNG happy path", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/screenshot.png`,
      case_id: null,
      mime_type: "image/png",
      filename: "screenshot.png",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "image/png");
});

Deno.test("IMGP-T22 — HEIC (iOS phone snap) is accepted", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/letter.heic`,
      case_id: null,
      mime_type: "image/heic",
      filename: "letter.heic",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "image/heic");
});

Deno.test("IMGP-T23 — HEIF is accepted", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/x.heif`,
      case_id: null,
      mime_type: "image/heif",
      filename: "x.heif",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "image/heif");
});

Deno.test("IMGP-T24 — WebP is accepted", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/x.webp`,
      case_id: null,
      mime_type: "image/webp",
      filename: "x.webp",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "image/webp");
});

Deno.test("IMGP-T25 — image/jpg alias is canonicalized to image/jpeg", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/x.jpg`,
      case_id: null,
      mime_type: "image/jpg",
      filename: "x.jpg",
    },
    UID_A,
  );
  // Canonicalized so the downstream branch sees one spelling.
  assertEquals(r.mime_type, "image/jpeg");
});

Deno.test("IMGP-T26 — application/pdf still works (no regression)", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/x.pdf`,
      case_id: null,
      mime_type: "application/pdf",
      filename: "x.pdf",
    },
    UID_A,
  );
  assertEquals(r.mime_type, "application/pdf");
});

Deno.test("IMGP-T27 — unsupported MIME (gif/tiff/docx) is still rejected", () => {
  for (const bad of [
    "image/gif",
    "image/tiff",
    "image/bmp",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain",
    "application/octet-stream",
  ]) {
    assertThrows(
      () =>
        parseAndValidateBody(
          {
            storage_path: `${UID_A}/general/x`,
            mime_type: bad,
            filename: "x",
          },
          UID_A,
        ),
      Error,
      "Only application/pdf or image",
    );
  }
});

Deno.test("IMGP-T28 — path-traversal check still fires for images", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_A}/../other/x.png`,
          mime_type: "image/png",
          filename: "x.png",
        },
        UID_A,
      ),
    Error,
    "must not contain ..",
  );
});

Deno.test("IMGP-T29 — user_id prefix check still fires for images", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `someone-else/general/x.jpg`,
          mime_type: "image/jpeg",
          filename: "x.jpg",
        },
        UID_A,
      ),
    Error,
    "must start with the caller's user_id",
  );
});

// =============================================================================
// 4. Source-contract — index.ts must wire the image branch
// =============================================================================

const INDEX_PATH = new URL("../index.ts", import.meta.url);

Deno.test("IMGP-T40 — index.ts imports isImageMime + normalizeImageMediaType", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, "isImageMime");
  assertStringIncludes(src, "normalizeImageMediaType");
});

Deno.test("IMGP-T41 — index.ts branches on image MIME before pdfjs", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  // The image branch must call runImageOcrPipeline (single Vision call,
  // no pdfjs text-layer step).
  assertStringIncludes(src, "runImageOcrPipeline");
  // And the original PDF path must still exist for non-image uploads.
  assertStringIncludes(src, "runParsePipeline");
});

Deno.test("IMGP-T42 — index.ts has a 10 MB image-size cap distinct from PDF cap", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, "MAX_IMAGE_BYTES");
  assertStringIncludes(src, "10 * 1024 * 1024");
});

Deno.test("IMGP-T43 — index.ts runImageOcrPipeline reuses the same Sonnet step", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  // Image path returns a ParsePipelineResult, downstream Sonnet
  // extraction call site is unchanged — same `runStructuredExtraction`
  // call applies to both branches.
  assertStringIncludes(src, "runStructuredExtraction");
  // No second extraction prompt was forked. We expect exactly two
  // mentions: one `export async function runStructuredExtraction(...)`
  // declaration + one shared call site. Anything > 2 means somebody
  // forked the prompt for the image path.
  const occurrences = src.match(/runStructuredExtraction\(/g) ?? [];
  assertEquals(
    occurrences.length,
    2,
    "There must be exactly one runStructuredExtraction declaration + one " +
      "call site (call site is shared by PDF + image paths). Got " +
      `${occurrences.length} matches.`,
  );
});

Deno.test("IMGP-T44 — runVisionOcrOnPage accepts a mediaType parameter", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  // The signature must take a third mediaType arg so non-PNG images
  // aren't mis-labelled to Anthropic.
  assertStringIncludes(src, "mediaType: string");
  assertStringIncludes(src, "media_type: mediaType");
});
