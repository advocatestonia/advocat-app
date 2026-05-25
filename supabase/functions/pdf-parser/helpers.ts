// pdf-parser/helpers.ts — pure helpers for the Pkg 2 Edge Function.
// -----------------------------------------------------------------------------
// Split out of `index.ts` so unit tests can import them WITHOUT importing
// `index.ts`'s top-level `serve(...)` listener (which would require
// --allow-net at test time and would block the test runner).
// -----------------------------------------------------------------------------

import {
  type ExtractedDoc,
  type LangCode,
} from "../_shared/pdf_extractor_prompt.ts";
import { isValidCaseId } from "../claude-proxy/active_case_injection.ts";

export interface RequestBody {
  storage_path: string;
  case_id: string | null;
  mime_type: string;
  filename: string;
}

/** Supported image MIME types. JPEG/PNG/HEIC/WebP — what phone cameras emit
 * and what users actually paste from screenshots. Anthropic Vision accepts
 * all four natively; HEIC is base64-passed and the model normalizes. */
export const SUPPORTED_IMAGE_MIME_TYPES: readonly string[] = [
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/heic",
  "image/heif",
  "image/webp",
];

/** Canonical Anthropic Vision media_type for a given input MIME. The
 * Anthropic API only accepts a fixed enum (image/jpeg, image/png,
 * image/gif, image/webp); we normalize HEIC/HEIF → jpeg (the actual
 * bytes are passed verbatim, the model treats it correctly), and
 * image/jpg → image/jpeg. */
export function normalizeImageMediaType(mime: string): string {
  const lc = mime.trim().toLowerCase();
  if (lc === "image/png") return "image/png";
  if (lc === "image/webp") return "image/webp";
  // jpg, jpeg, heic, heif → jpeg.
  return "image/jpeg";
}

/** Returns true if `mime` is one of the supported image types. */
export function isImageMime(mime: string): boolean {
  const lc = mime.trim().toLowerCase();
  return SUPPORTED_IMAGE_MIME_TYPES.includes(lc);
}

/** Returns true if `mime` is application/pdf (or the loose `pdf` alias). */
export function isPdfMime(mime: string): boolean {
  return /^application\/pdf$|^pdf$/i.test(mime.trim());
}

/** Parse + validate the POST body. Throws on any structural issue. */
export function parseAndValidateBody(raw: unknown, userId: string): RequestBody {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("Invalid body");
  }
  const obj = raw as Record<string, unknown>;

  const storagePath = obj.storage_path;
  if (typeof storagePath !== "string" || storagePath.length === 0) {
    throw new Error("storage_path is required");
  }
  // Pin to the caller's uid prefix — defends against another user's path.
  // Layout: <user_id>/<case_id_or_general>/<filename>
  if (!storagePath.startsWith(`${userId}/`)) {
    throw new Error("storage_path must start with the caller's user_id");
  }
  // Reject path traversal.
  if (storagePath.includes("..")) {
    throw new Error("storage_path must not contain ..");
  }

  const mimeType = obj.mime_type;
  if (typeof mimeType !== "string" || mimeType.length === 0) {
    throw new Error("mime_type is required");
  }
  // Accept PDF and the supported image MIMEs. Normalize to lowercase for
  // downstream branching; canonicalize `pdf` → `application/pdf`.
  let canonicalMime: string;
  if (isPdfMime(mimeType)) {
    canonicalMime = "application/pdf";
  } else if (isImageMime(mimeType)) {
    canonicalMime = mimeType.trim().toLowerCase();
    // Collapse image/jpg → image/jpeg so downstream sees one spelling.
    if (canonicalMime === "image/jpg") canonicalMime = "image/jpeg";
  } else {
    throw new Error(
      "Only application/pdf or image/(jpeg|png|heic|heif|webp) is supported",
    );
  }

  const filename = obj.filename;
  if (typeof filename !== "string" || filename.length === 0) {
    throw new Error("filename is required");
  }
  if (filename.length > 255) {
    throw new Error("filename too long (max 255)");
  }

  let caseId: string | null = null;
  if (obj.case_id !== undefined && obj.case_id !== null) {
    if (typeof obj.case_id !== "string") {
      throw new Error("case_id must be a string or null");
    }
    if (!isValidCaseId(obj.case_id)) {
      throw new Error("case_id must be a UUID");
    }
    caseId = obj.case_id;
  }

  return {
    storage_path: storagePath,
    case_id: caseId,
    mime_type: canonicalMime,
    filename,
  };
}

/** OCR result types — exposed for tests via the helper exports below. */
export interface PageText {
  /** 1-indexed page number. */
  page: number;
  /** Plain text — `''` if neither extraction nor OCR yielded anything. */
  text: string;
  /** Source: 'text' = text layer, 'vision' = Vision OCR, 'empty' = neither. */
  source: "text" | "vision" | "empty";
}

/** Stitch per-page text with `--- PAGE N ---` markers between non-empty pages. */
export function stitchPages(pages: PageText[]): string {
  const parts: string[] = [];
  for (const p of pages) {
    if (p.text.trim().length === 0) continue;
    parts.push(`--- PAGE ${p.page} ---`);
    parts.push(p.text);
  }
  return parts.join("\n\n");
}

/** key_extractions JSON shape — what gets stored in the jsonb column and
 * what the chat-prompt injection (Pkg 1.B) reads. */
export function extractedToKeyExtractions(
  e: ExtractedDoc,
  pagesLang: LangCode[],
): Record<string, unknown> {
  return {
    doc_type: e.doc_type,
    doc_date: e.doc_date,
    parties: e.parties,
    case_numbers: e.case_numbers,
    key_facts: e.key_facts,
    diagnoses_if_medical: e.diagnoses_if_medical,
    monetary_amounts: e.monetary_amounts,
    deadlines: e.deadlines,
    pages_lang: pagesLang,
  };
}

/**
 * Base64 encoder — Deno provides btoa, but it can't handle arbitrary bytes
 * without a Latin-1 round-trip. Use a chunked Uint8Array → string → btoa
 * path. Kept inline so the module has no extra deps.
 */
export function encodeBase64(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  let binary = "";
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const sub = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...sub);
  }
  return btoa(binary);
}
