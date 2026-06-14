// case-dossier-export/handler.ts — pure logic for the Case Dossier Export.
// -----------------------------------------------------------------------------
// Feature: "Case Dossier Export" (PDF дело одним кликом). A user with a case
// (Migri / tenancy / dismissal …) hands a single document to a lawyer, a court,
// or a complaint body containing EVERYTHING about the case: header facts,
// chronology, deadlines, the document list, and (optionally) the latest AI
// summary.
//
// Architecture: this edge function is a thin AGGREGATOR. It pulls the case
// header, timeline events, deadlines, and document list (already exposed by
// the case-memory tables), assembles a single Markdown dossier, and then POSTs
// that Markdown to the EXISTING `pdf-generator` edge function. pdf-generator
// owns the HTML template, the case-documents bucket upload, the signed URL, and
// the case_documents row insert (+ its own RLS / ownership re-check). We never
// duplicate the storage or template logic, and we add NO new tables.
//
// This module is pure with respect to the Deno runtime: every IO dependency
// (the case-data fetcher and the pdf-generator caller) is dependency-injected,
// so the dossier-assembly logic is fully unit-testable without a network.
// -----------------------------------------------------------------------------

// ─── Public request / response contracts ─────────────────────────────────────

/** Section toggles — the Flutter preview screen lets the user switch whole
 *  sections on/off before exporting. The case header is always included. */
export interface DossierSections {
  timeline: boolean;
  deadlines: boolean;
  documents: boolean;
  aiSummary: boolean;
}

export interface DossierExportRequest {
  /** UUID of the case to export. Ownership is re-verified downstream by
   *  pdf-generator (service-role insert guard) AND we only ever query rows
   *  scoped to the authenticated user. */
  case_id: string;
  /** Which sections to include. Missing keys default to `true` (full dossier)
   *  EXCEPT aiSummary which is included only when a summary actually exists. */
  sections?: Partial<DossierSections>;
  /** UI language for section headings. Falls back to the case language, then
   *  to "en". Only affects static labels — case content is verbatim. */
  locale?: string;
}

export interface DossierExportSuccess {
  kind: "success";
  status: 200;
  body: {
    download_url: string;
    storage_path: string;
    filename: string;
    document_id: string | null;
    /** Char length of the assembled markdown — handy for assertions / UI. */
    dossier_length: number;
  };
}

export interface DossierExportError {
  kind: "error";
  status: 400 | 403 | 404 | 500 | 502;
  body: { error: string };
}

export type DossierExportResult = DossierExportSuccess | DossierExportError;

// ─── Aggregated case-data shapes (what the fetcher must return) ───────────────

export interface CaseHeader {
  id: string;
  title: string;
  jurisdiction: string | null;
  case_type: string | null;
  status: string | null;
  case_numbers: string[];
  parties: string[];
  authorities: string[];
  summary: string | null;
  language: string | null;
  created_at: string | null;
}

export interface TimelineEventRow {
  event_type: string;
  title: string;
  summary: string | null;
  occurred_at: string | null;
}

export interface DeadlineRow {
  title: string;
  description: string | null;
  statute_basis: string | null;
  deadline_at: string | null;
  status: string | null;
  priority: string | null;
  holiday_shifted: boolean;
}

export interface DocumentRow {
  filename: string;
  doc_type: string | null;
  doc_date: string | null;
  parsed_summary: string | null;
}

/** Everything the assembler needs. `header` null ⇒ case not found / not owned. */
export interface CaseDossierData {
  header: CaseHeader | null;
  timeline: TimelineEventRow[];
  deadlines: DeadlineRow[];
  documents: DocumentRow[];
}

// ─── Validation ─────────────────────────────────────────────────────────────

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function validateDossierRequest(
  body: unknown
): { ok: true; req: DossierExportRequest } | DossierExportError {
  if (!body || typeof body !== "object") {
    return {
      kind: "error",
      status: 400,
      body: { error: "Request body must be a JSON object" },
    };
  }
  const b = body as Record<string, unknown>;
  if (typeof b.case_id !== "string" || !UUID_RE.test(b.case_id)) {
    return {
      kind: "error",
      status: 400,
      body: { error: "case_id must be a valid UUID" },
    };
  }
  const req: DossierExportRequest = { case_id: b.case_id };

  if (b.sections && typeof b.sections === "object") {
    const s = b.sections as Record<string, unknown>;
    const sections: Partial<DossierSections> = {};
    if (typeof s.timeline === "boolean") sections.timeline = s.timeline;
    if (typeof s.deadlines === "boolean") sections.deadlines = s.deadlines;
    if (typeof s.documents === "boolean") sections.documents = s.documents;
    if (typeof s.aiSummary === "boolean") sections.aiSummary = s.aiSummary;
    req.sections = sections;
  }
  if (typeof b.locale === "string") {
    req.locale = b.locale.trim().slice(0, 10);
  }
  return { ok: true, req };
}

/** Resolve the effective section toggles. Defaults: everything ON. */
export function resolveSections(
  partial: Partial<DossierSections> | undefined
): DossierSections {
  return {
    timeline: partial?.timeline ?? true,
    deadlines: partial?.deadlines ?? true,
    documents: partial?.documents ?? true,
    aiSummary: partial?.aiSummary ?? true,
  };
}

// ─── Localised section labels ────────────────────────────────────────────────
// Only a tiny static label set is localised here for the primary case locales;
// everything else falls back to English. Case CONTENT is never translated — it
// is reproduced verbatim.

interface Labels {
  dossier: string;
  facts: string;
  jurisdiction: string;
  caseType: string;
  status: string;
  caseNumbers: string;
  parties: string;
  authorities: string;
  aiSummary: string;
  timeline: string;
  deadlines: string;
  documents: string;
  noItems: string;
  priority: string;
  basis: string;
  shifted: string;
  generated: string;
}

const LABELS: Record<string, Labels> = {
  en: {
    dossier: "Case Dossier",
    facts: "Case Facts",
    jurisdiction: "Jurisdiction",
    caseType: "Case type",
    status: "Status",
    caseNumbers: "Case numbers",
    parties: "Parties",
    authorities: "Authorities",
    aiSummary: "AI Summary",
    timeline: "Chronology",
    deadlines: "Deadlines",
    documents: "Documents",
    noItems: "None recorded.",
    priority: "priority",
    basis: "basis",
    shifted: "holiday-shifted",
    generated: "Generated by Advocat.ee",
  },
  et: {
    dossier: "Toimik",
    facts: "Asjaolud",
    jurisdiction: "Jurisdiktsioon",
    caseType: "Asja liik",
    status: "Staatus",
    caseNumbers: "Asja numbrid",
    parties: "Pooled",
    authorities: "Ametiasutused",
    aiSummary: "AI kokkuvõte",
    timeline: "Kronoloogia",
    deadlines: "Tähtajad",
    documents: "Dokumendid",
    noItems: "Pole kirjeid.",
    priority: "prioriteet",
    basis: "alus",
    shifted: "pühade tõttu nihutatud",
    generated: "Loodud Advocat.ee poolt",
  },
  fi: {
    dossier: "Asiakirjavihko",
    facts: "Tosiseikat",
    jurisdiction: "Lainkäyttöalue",
    caseType: "Asian tyyppi",
    status: "Tila",
    caseNumbers: "Asianumerot",
    parties: "Osapuolet",
    authorities: "Viranomaiset",
    aiSummary: "AI-yhteenveto",
    timeline: "Aikajana",
    deadlines: "Määräajat",
    documents: "Asiakirjat",
    noItems: "Ei merkintöjä.",
    priority: "prioriteetti",
    basis: "peruste",
    shifted: "pyhäpäivän vuoksi siirretty",
    generated: "Luotu Advocat.ee-palvelussa",
  },
  ru: {
    dossier: "Досье по делу",
    facts: "Обстоятельства дела",
    jurisdiction: "Юрисдикция",
    caseType: "Тип дела",
    status: "Статус",
    caseNumbers: "Номера дела",
    parties: "Стороны",
    authorities: "Органы власти",
    aiSummary: "Сводка ИИ",
    timeline: "Хронология",
    deadlines: "Сроки",
    documents: "Документы",
    noItems: "Записей нет.",
    priority: "приоритет",
    basis: "основание",
    shifted: "перенесён из-за праздника",
    generated: "Сгенерировано Advocat.ee",
  },
};

function labelsFor(locale: string | undefined): Labels {
  if (!locale) return LABELS.en;
  const key = locale.toLowerCase().split(/[-_]/)[0];
  return LABELS[key] ?? LABELS.en;
}

// ─── Markdown helpers ────────────────────────────────────────────────────────

/** Escape Markdown control characters so verbatim case text cannot inject
 *  headings / lists / emphasis that distort the dossier. Newlines are folded
 *  into a single space to avoid breaking list rows. */
export function mdEscape(text: string): string {
  return text
    .replace(/[\\`*_#>\[\]]/g, (m) => `\\${m}`)
    .replace(/\r?\n/g, " ")
    .trim();
}

/** Format an ISO timestamp / date as YYYY-MM-DD; pass through if unparseable. */
export function fmtDate(raw: string | null | undefined): string {
  if (!raw) return "—";
  const d = new Date(raw);
  if (isNaN(d.getTime())) return mdEscape(String(raw));
  return d.toISOString().slice(0, 10);
}

// ─── Dossier assembly ────────────────────────────────────────────────────────

/**
 * Build the full dossier Markdown from aggregated case data + section toggles.
 * Returns `{ markdown, title }`. The title becomes both the pdf-generator
 * document title and the basis of the suggested filename.
 *
 * Limits: the markdown is hard-capped at ~99 000 chars to respect
 * pdf-generator's `body_markdown` ≤100 000 validation. We truncate and
 * annotate rather than letting the downstream call 400 out.
 */
export function buildDossierMarkdown(
  data: CaseDossierData,
  sections: DossierSections,
  locale: string | undefined
): { markdown: string; title: string } {
  const h = data.header!;
  const L = labelsFor(locale ?? h.language ?? undefined);
  const lines: string[] = [];

  const title = `${L.dossier}: ${h.title}`.slice(0, 180);

  // ── Header / facts (always included) ──────────────────────────────────
  lines.push(`## ${L.facts}`);
  const fact = (label: string, value: string | null | undefined) => {
    if (value && value.trim().length > 0) {
      lines.push(`- **${label}:** ${mdEscape(value)}`);
    }
  };
  fact(L.jurisdiction, h.jurisdiction);
  fact(L.caseType, h.case_type);
  fact(L.status, h.status);
  if (h.case_numbers.length > 0) {
    fact(L.caseNumbers, h.case_numbers.join(", "));
  }
  if (h.parties.length > 0) fact(L.parties, h.parties.join("; "));
  if (h.authorities.length > 0) {
    fact(L.authorities, h.authorities.join("; "));
  }
  lines.push("");

  // ── AI summary (optional) ─────────────────────────────────────────────
  if (sections.aiSummary && h.summary && h.summary.trim().length > 0) {
    lines.push(`## ${L.aiSummary}`);
    lines.push(mdEscape(h.summary));
    lines.push("");
  }

  // ── Chronology (optional) ─────────────────────────────────────────────
  if (sections.timeline) {
    lines.push(`## ${L.timeline}`);
    if (data.timeline.length === 0) {
      lines.push(L.noItems);
    } else {
      // Sort ascending by occurred_at so the dossier reads as a narrative.
      const sorted = [...data.timeline].sort((a, b) =>
        (a.occurred_at ?? "").localeCompare(b.occurred_at ?? "")
      );
      for (const ev of sorted) {
        const when = fmtDate(ev.occurred_at);
        lines.push(`- **${when}** — ${mdEscape(ev.title)}`);
        if (ev.summary && ev.summary.trim().length > 0) {
          lines.push(`  ${mdEscape(ev.summary)}`);
        }
      }
    }
    lines.push("");
  }

  // ── Deadlines (optional) ──────────────────────────────────────────────
  if (sections.deadlines) {
    lines.push(`## ${L.deadlines}`);
    if (data.deadlines.length === 0) {
      lines.push(L.noItems);
    } else {
      const sorted = [...data.deadlines].sort((a, b) =>
        (a.deadline_at ?? "").localeCompare(b.deadline_at ?? "")
      );
      for (const d of sorted) {
        const when = fmtDate(d.deadline_at);
        const meta: string[] = [];
        if (d.priority) meta.push(`${L.priority}: ${mdEscape(d.priority)}`);
        if (d.statute_basis) {
          meta.push(`${L.basis}: ${mdEscape(d.statute_basis)}`);
        }
        if (d.holiday_shifted) meta.push(L.shifted);
        const suffix = meta.length > 0 ? ` (${meta.join(", ")})` : "";
        lines.push(`- **${when}** — ${mdEscape(d.title)}${suffix}`);
        if (d.description && d.description.trim().length > 0) {
          lines.push(`  ${mdEscape(d.description)}`);
        }
      }
    }
    lines.push("");
  }

  // ── Documents (optional) ──────────────────────────────────────────────
  if (sections.documents) {
    lines.push(`## ${L.documents}`);
    if (data.documents.length === 0) {
      lines.push(L.noItems);
    } else {
      for (const doc of data.documents) {
        const parts: string[] = [`**${mdEscape(doc.filename)}**`];
        if (doc.doc_type) parts.push(mdEscape(doc.doc_type));
        if (doc.doc_date) parts.push(fmtDate(doc.doc_date));
        lines.push(`- ${parts.join(" · ")}`);
        if (doc.parsed_summary && doc.parsed_summary.trim().length > 0) {
          lines.push(`  ${mdEscape(doc.parsed_summary)}`);
        }
      }
    }
    lines.push("");
  }

  let markdown = lines.join("\n");

  // Hard cap to respect pdf-generator's body_markdown ≤100k guard. Truncate
  // and annotate rather than letting the downstream call 400 out.
  const MAX = 99_000;
  if (markdown.length > MAX) {
    markdown = markdown.slice(0, MAX) + "\n\n_…(truncated)_\n";
  }

  return { markdown, title };
}

// ─── Dependency-injected IO ──────────────────────────────────────────────────

/** Pulls all case data scoped to a single owner. Implementations MUST scope
 *  every query to (case_id, user_id) so a forged case_id never leaks foreign
 *  rows. Returns header=null when the case is not the caller's. */
export type CaseDataFetcher = (
  caseId: string,
  userId: string
) => Promise<CaseDossierData>;

export interface PdfGeneratorResponse {
  download_url: string;
  storage_path: string;
  filename: string;
  document_id: string | null;
}

/** Posts the assembled markdown to the pdf-generator edge function and returns
 *  its response. Implementations carry the caller's JWT so pdf-generator runs
 *  under the same identity + RLS + ownership re-check. */
export type PdfGeneratorCaller = (payload: {
  title: string;
  body_markdown: string;
  doc_type: string;
  locale: string;
  case_id: string;
}) => Promise<
  | { ok: true; body: PdfGeneratorResponse }
  | { ok: false; status: number; error: string }
>;

// ─── Orchestrator ────────────────────────────────────────────────────────────

export interface RunDossierExportOptions {
  body: unknown;
  userId: string;
  fetchCaseData: CaseDataFetcher;
  callPdfGenerator: PdfGeneratorCaller;
}

export async function runDossierExport(
  opts: RunDossierExportOptions
): Promise<DossierExportResult> {
  const v = validateDossierRequest(opts.body);
  if (!("ok" in v)) return v;
  const req = v.req;

  let data: CaseDossierData;
  try {
    data = await opts.fetchCaseData(req.case_id, opts.userId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return {
      kind: "error",
      status: 500,
      body: { error: `case_data_fetch_failed: ${msg.slice(0, 200)}` },
    };
  }

  if (!data.header) {
    // Case missing OR not owned — same response (no existence oracle).
    return {
      kind: "error",
      status: 404,
      body: { error: "Case not found or not owned" },
    };
  }

  const sections = resolveSections(req.sections);
  const { markdown, title } = buildDossierMarkdown(data, sections, req.locale);

  const locale = (req.locale ?? data.header.language ?? "en").slice(0, 10);

  let gen:
    | { ok: true; body: PdfGeneratorResponse }
    | { ok: false; status: number; error: string };
  try {
    gen = await opts.callPdfGenerator({
      title,
      body_markdown: markdown,
      doc_type: "case_dossier",
      locale,
      case_id: req.case_id,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return {
      kind: "error",
      status: 502,
      body: { error: `pdf_generator_failed: ${msg.slice(0, 200)}` },
    };
  }

  if (!gen.ok) {
    // Surface the downstream auth/ownership verdict faithfully.
    const status = gen.status === 403 ? 403 : 502;
    return {
      kind: "error",
      status,
      body: {
        error: `pdf_generator_${gen.status}: ${gen.error.slice(0, 200)}`,
      },
    };
  }

  return {
    kind: "success",
    status: 200,
    body: {
      download_url: gen.body.download_url,
      storage_path: gen.body.storage_path,
      filename: gen.body.filename,
      document_id: gen.body.document_id,
      dossier_length: markdown.length,
    },
  };
}
