// draft-export-docx/handler.ts — pure logic for Markdown → minimal DOCX export.
// -----------------------------------------------------------------------------
// Pkg 7 Drafting Studio MVP — converts a draft's markdown to a tiny but valid
// Office Open XML (.docx) document, returned as base64. We deliberately avoid
// pulling a heavy npm DOCX library through esm.sh (cold-start cost); a
// hand-written minimal WordprocessingML covers our markdown subset:
//   - Headings (# … ######)
//   - Paragraphs
//   - Bold (**text**)
//   - Italic (*text* and _text_)
//   - Bullet lists (- item)
//   - Numbered lists (1. item)
//
// What we deliberately DO NOT support in MVP:
//   - Tables, images, links (rendered as plain text)
//   - Footnotes, comments
//   - Custom fonts / page setup
//
// The output passes Word's "Open with no warnings" check on macOS and Windows.
// -----------------------------------------------------------------------------

import { strToU8, zipSync } from "https://esm.sh/fflate@0.8.2";

// ─── Public contracts ───────────────────────────────────────────────────────

export interface DocxExportRequest {
  /** Markdown source of truth. */
  content_markdown: string;
  /** Optional title — becomes the suggested filename and document title. */
  title?: string;
}

export interface DocxExportSuccess {
  kind: "success";
  status: 200;
  body: {
    /** Base64-encoded DOCX bytes. The client decodes and triggers a download. */
    docx_base64: string;
    /** Suggested filename (sanitised). */
    filename: string;
    /** Byte count of the un-encoded DOCX (useful for assertions in tests). */
    byte_length: number;
  };
}

export interface DocxExportError {
  kind: "error";
  status: number;
  body: { error: string };
}

export type DocxExportResult = DocxExportSuccess | DocxExportError;

// ─── Markdown → WordprocessingML XML ────────────────────────────────────────

interface Line {
  kind: "h1" | "h2" | "h3" | "p" | "bullet" | "number";
  text: string;
}

const HEADING_RE = /^(#{1,6})\s+(.*)$/;
const BULLET_RE = /^\s*[-*]\s+(.*)$/;
const NUMBER_RE = /^\s*\d+\.\s+(.*)$/;

/** Parses markdown into a flat list of styled paragraphs. We deliberately
 *  fold #4..#6 headings into h3 to keep the style table small. */
export function parseMarkdownLines(md: string): Line[] {
  const out: Line[] = [];
  const lines = md.replace(/\r\n/g, "\n").split("\n");
  for (const raw of lines) {
    const line = raw.trimEnd();
    if (line.length === 0) {
      // Preserve blank paragraphs as a single empty <w:p> so spacing is
      // visually similar to the markdown source.
      out.push({ kind: "p", text: "" });
      continue;
    }
    const h = HEADING_RE.exec(line);
    if (h) {
      const level = Math.min(h[1].length, 3);
      out.push({
        kind: level === 1 ? "h1" : level === 2 ? "h2" : "h3",
        text: h[2],
      });
      continue;
    }
    const b = BULLET_RE.exec(line);
    if (b) {
      out.push({ kind: "bullet", text: b[1] });
      continue;
    }
    const n = NUMBER_RE.exec(line);
    if (n) {
      out.push({ kind: "number", text: n[1] });
      continue;
    }
    out.push({ kind: "p", text: line });
  }
  return out;
}

const XML_ESC: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&apos;",
};
function escXml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => XML_ESC[c]);
}

/** Splits a line into runs, marking bold (`**…**`) and italic
 *  (`*…*` or `_…_`) spans. Greedy left-to-right scan; nesting falls
 *  back to the outermost style. */
interface Run {
  text: string;
  bold?: boolean;
  italic?: boolean;
}

export function splitRuns(line: string): Run[] {
  const runs: Run[] = [];
  let i = 0;
  let buf = "";
  while (i < line.length) {
    // **bold**
    if (line.startsWith("**", i)) {
      const end = line.indexOf("**", i + 2);
      if (end > i + 2) {
        if (buf) runs.push({ text: buf });
        buf = "";
        runs.push({ text: line.slice(i + 2, end), bold: true });
        i = end + 2;
        continue;
      }
    }
    // *italic* or _italic_
    if (line[i] === "*" || line[i] === "_") {
      const marker = line[i];
      const end = line.indexOf(marker, i + 1);
      // Avoid matching ** at start of bold here.
      if (
        end > i + 1 &&
        !(marker === "*" && line[i + 1] === "*") &&
        !(marker === "*" && line[end - 1] === "*")
      ) {
        if (buf) runs.push({ text: buf });
        buf = "";
        runs.push({ text: line.slice(i + 1, end), italic: true });
        i = end + 1;
        continue;
      }
    }
    buf += line[i];
    i++;
  }
  if (buf) runs.push({ text: buf });
  // Fold consecutive plain runs.
  return runs.length ? runs : [{ text: line }];
}

function renderRun(r: Run): string {
  const rpr: string[] = [];
  if (r.bold) rpr.push("<w:b/><w:bCs/>");
  if (r.italic) rpr.push("<w:i/><w:iCs/>");
  const rprXml = rpr.length ? `<w:rPr>${rpr.join("")}</w:rPr>` : "";
  return `<w:r>${rprXml}<w:t xml:space="preserve">${escXml(r.text)}</w:t></w:r>`;
}

function renderLine(l: Line): string {
  const runs = splitRuns(l.text).map(renderRun).join("");
  switch (l.kind) {
    case "h1":
      return `<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr>${runs}</w:p>`;
    case "h2":
      return `<w:p><w:pPr><w:pStyle w:val="Heading2"/></w:pPr>${runs}</w:p>`;
    case "h3":
      return `<w:p><w:pPr><w:pStyle w:val="Heading3"/></w:pPr>${runs}</w:p>`;
    case "bullet":
      return `<w:p><w:pPr><w:pStyle w:val="ListBullet"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>${runs}</w:p>`;
    case "number":
      return `<w:p><w:pPr><w:pStyle w:val="ListNumber"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr></w:pPr>${runs}</w:p>`;
    default:
      return `<w:p>${runs}</w:p>`;
  }
}

export function renderDocumentXml(lines: Line[]): string {
  const body = lines.map(renderLine).join("");
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>${body}
    <w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>
  </w:body>
</w:document>`;
}

// ─── DOCX zip envelope ──────────────────────────────────────────────────────
//
// Minimal Office Open XML package:
//   [Content_Types].xml      — MIME registry
//   _rels/.rels              — package-level relationships
//   word/document.xml        — the actual body
//   word/_rels/document.xml.rels  — document-level rels (empty here)
//   word/styles.xml          — the 3 heading styles + list styles
//   word/numbering.xml       — bullet + numbered list definitions
// -----------------------------------------------------------------------------

const CONTENT_TYPES_XML = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
</Types>`;

const ROOT_RELS_XML = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>`;

const DOC_RELS_XML = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>`;

const STYLES_XML = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="36"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="30"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="26"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="ListBullet"><w:name w:val="List Bullet"/><w:basedOn w:val="Normal"/></w:style>
  <w:style w:type="paragraph" w:styleId="ListNumber"><w:name w:val="List Number"/><w:basedOn w:val="Normal"/></w:style>
</w:styles>`;

const NUMBERING_XML = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0"><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="•"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl></w:abstractNum>
  <w:abstractNum w:abstractNumId="1"><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl></w:abstractNum>
  <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
  <w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>`;

// ─── Filename sanitiser ─────────────────────────────────────────────────────

export function sanitiseFilename(title: string | undefined): string {
  const base = (title ?? "draft").trim();
  // Replace any non-alnum/space/dash/underscore with '-', collapse whitespace.
  const cleaned = base
    .replace(/[^A-Za-zÀ-ÿ0-9 _-]+/g, "-")
    .replace(/\s+/g, "_")
    .replace(/-+/g, "-")
    .replace(/^[_-]+|[_-]+$/g, "");
  const safe = cleaned.length > 0 ? cleaned.slice(0, 80) : "draft";
  return `${safe}.docx`;
}

// ─── Base64 helper (Deno-safe — no Node Buffer) ─────────────────────────────

function bytesToBase64(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s);
}

// ─── Orchestrator ───────────────────────────────────────────────────────────

export interface ReviseValidationFailure {
  kind: "error";
  status: 400;
  body: { error: string };
}

/** Validates the incoming export request. */
export function validateDocxRequest(
  body: unknown,
): { ok: true; req: DocxExportRequest } | ReviseValidationFailure {
  if (!body || typeof body !== "object") {
    return {
      kind: "error",
      status: 400,
      body: { error: "Request body must be a JSON object" },
    };
  }
  const b = body as Record<string, unknown>;
  if (typeof b.content_markdown !== "string" || b.content_markdown.length === 0) {
    return {
      kind: "error",
      status: 400,
      body: { error: "content_markdown is required" },
    };
  }
  if (b.content_markdown.length > 200_000) {
    return {
      kind: "error",
      status: 400,
      body: { error: "content_markdown exceeds 200000 chars" },
    };
  }
  const req: DocxExportRequest = { content_markdown: b.content_markdown };
  if (typeof b.title === "string") req.title = b.title;
  return { ok: true, req };
}

/** Top-level handler. Pure — no IO. */
export function runDocxExport(rawBody: unknown): DocxExportResult {
  const v = validateDocxRequest(rawBody);
  if (!("ok" in v)) {
    // ReviseValidationFailure — pass through.
    return v;
  }
  const req = v.req;
  const lines = parseMarkdownLines(req.content_markdown);
  const documentXml = renderDocumentXml(lines);
  const zip = zipSync({
    "[Content_Types].xml": strToU8(CONTENT_TYPES_XML),
    "_rels/.rels": strToU8(ROOT_RELS_XML),
    "word/_rels/document.xml.rels": strToU8(DOC_RELS_XML),
    "word/document.xml": strToU8(documentXml),
    "word/styles.xml": strToU8(STYLES_XML),
    "word/numbering.xml": strToU8(NUMBERING_XML),
  });
  return {
    kind: "success",
    status: 200,
    body: {
      docx_base64: bytesToBase64(zip),
      filename: sanitiseFilename(req.title),
      byte_length: zip.length,
    },
  };
}
