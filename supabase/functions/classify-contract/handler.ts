// classify-contract/handler.ts — pure business logic for the auto-detection
// chip ("Review this contract") shown after a PDF upload.
// -----------------------------------------------------------------------------
// What this does (cheap, fast, never-throws):
//   1. Load the uploaded document row (RLS: same-user only).
//   2. Take ONLY the first-page text slice (budget capped) so we send a
//      tiny prompt to Haiku.
//   3. Ask Haiku a single yes/no question with a confidence score and an
//      optional contract-type hint.
//   4. If confidence > 0.7 → tell the client to show the review chip.
//
// All business logic is pure + dependency-injected so the tests can mock
// the loader + the Haiku call.
// -----------------------------------------------------------------------------

// ─── Tunables ───────────────────────────────────────────────────────────────

/** Confidence cutoff — strictly greater than. */
export const CLASSIFY_CONFIDENCE_THRESHOLD = 0.7;

/** Char budget passed to Haiku (~ first page on a 12-pt document). */
export const FIRST_PAGE_CHAR_BUDGET = 3_000;

// ─── Public contracts ───────────────────────────────────────────────────────

export type ContractTypeHint =
  | "dealer"
  | "saas"
  | "nda"
  | "employment"
  | "m&a"
  | "real_estate";

/** Allowed hints — keep in sync with ContractTypeHint. */
const CONTRACT_TYPE_HINTS: readonly ContractTypeHint[] = [
  "dealer",
  "saas",
  "nda",
  "employment",
  "m&a",
  "real_estate",
] as const;

export interface ClassifyRequest {
  case_document_id: string;
}

export interface ClassifyResult {
  is_contract: boolean;
  confidence: number; // 0..1, clamped
  contract_type_hint?: ContractTypeHint;
  /**
   * Optional machine-readable reason for negatives (no_text, not_found,
   * planner_error, low_confidence). Useful for client telemetry; not shown
   * to users.
   */
  reason?: string;
}

export interface DocumentRow {
  id: string;
  user_id: string;
  filename: string;
  parsed_text: string | null;
}

export type DocumentLoader = (
  userId: string,
  documentId: string,
) => Promise<DocumentRow | null>;

export interface HaikuRequest {
  systemPrompt: string;
  documentText: string;
  filename: string;
}

export interface HaikuResponse {
  is_contract: boolean;
  confidence: number;
  contract_type_hint?: ContractTypeHint | string;
}

export type HaikuCaller = (req: HaikuRequest) => Promise<HaikuResponse>;

export interface ClassifyDeps {
  loadDocument: DocumentLoader;
  callHaiku: HaikuCaller;
}

export interface ClassifyArgs {
  userId: string;
  documentId: string;
  deps: ClassifyDeps;
}

// ─── Validation ─────────────────────────────────────────────────────────────

export type ValidatedRequest =
  | { ok: true; value: ClassifyRequest }
  | { ok: false; error: string };

export function validateRequest(raw: unknown): ValidatedRequest {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const obj = raw as Record<string, unknown>;
  const id = obj.case_document_id;
  if (typeof id !== "string" || id.trim() === "") {
    return {
      ok: false,
      error: "case_document_id is required and must be a non-empty string",
    };
  }
  if (id.length > 128) {
    return { ok: false, error: "case_document_id too long" };
  }
  return { ok: true, value: { case_document_id: id } };
}

// ─── System prompt (≤ 200 tokens) ───────────────────────────────────────────

const SYSTEM_PROMPT = [
  "You are a contract detector. The user just uploaded a document.",
  "Decide whether the FIRST PAGE TEXT below looks like a legal contract",
  "(agreement, terms, deed, employment offer, NDA, lease, etc.) — NOT a",
  "court decision, invoice, ID document, certificate, letter, or article.",
  "",
  "Reply with ONE JSON object, no prose, no code fences:",
  '{"is_contract":true|false,"confidence":0.0..1.0,"contract_type_hint":"dealer"|"saas"|"nda"|"employment"|"m&a"|"real_estate"|null}',
  "",
  "Rules:",
  "- confidence reflects how sure you are about is_contract.",
  '- contract_type_hint must be null unless is_contract=true AND confidence>=0.7.',
  "- Use ONLY these hint values: dealer, saas, nda, employment, m&a, real_estate.",
  "- Do not invent other hint values. Do not add commentary.",
].join("\n");

export function buildSystemPrompt(): string {
  return SYSTEM_PROMPT;
}

// ─── Core ───────────────────────────────────────────────────────────────────

export async function classifyDocument(
  args: ClassifyArgs,
): Promise<ClassifyResult> {
  const { userId, documentId, deps } = args;

  // 1. Load the document — same-user only (the loader is bound to RLS).
  let doc: DocumentRow | null;
  try {
    doc = await deps.loadDocument(userId, documentId);
  } catch (e) {
    return {
      is_contract: false,
      confidence: 0,
      reason: "load_error:" + safeMessage(e).slice(0, 60),
    };
  }
  if (!doc) {
    return { is_contract: false, confidence: 0, reason: "not_found" };
  }

  // 2. No parsed text → can't classify. The parser ran async; the chip
  //    just won't appear yet. UX-wise this is fine because the upload
  //    bubble itself is enough.
  const raw = (doc.parsed_text ?? "").trim();
  if (raw.length === 0) {
    return { is_contract: false, confidence: 0, reason: "no_text" };
  }

  // 3. Truncate to first-page budget.
  const truncated = raw.length > FIRST_PAGE_CHAR_BUDGET
    ? raw.slice(0, FIRST_PAGE_CHAR_BUDGET)
    : raw;

  // 4. Ask Haiku.
  let resp: HaikuResponse;
  try {
    resp = await deps.callHaiku({
      systemPrompt: buildSystemPrompt(),
      documentText: truncated,
      filename: doc.filename,
    });
  } catch (e) {
    return {
      is_contract: false,
      confidence: 0,
      reason: "planner_error:" + safeMessage(e).slice(0, 60),
    };
  }

  // 5. Sanitize the response.
  const confidence = clampConfidence(resp.confidence);
  const haikuSaidContract = resp.is_contract === true;
  const aboveThreshold = confidence > CLASSIFY_CONFIDENCE_THRESHOLD;

  // Threshold gating: show the chip only on a positive Haiku verdict AND a
  // confidence strictly above the threshold. The client uses is_contract to
  // decide visibility; confidence is included for telemetry.
  const isContract = haikuSaidContract && aboveThreshold;

  // 6. Type hint — only kept on a clean positive.
  let hint: ContractTypeHint | undefined;
  if (isContract && typeof resp.contract_type_hint === "string") {
    const normalised = resp.contract_type_hint.toLowerCase();
    if (
      (CONTRACT_TYPE_HINTS as readonly string[]).includes(normalised)
    ) {
      hint = normalised as ContractTypeHint;
    }
  }

  const out: ClassifyResult = {
    is_contract: isContract,
    confidence,
  };
  if (hint) out.contract_type_hint = hint;
  if (!isContract && haikuSaidContract && !aboveThreshold) {
    out.reason = "low_confidence";
  } else if (!isContract && !haikuSaidContract) {
    out.reason = "not_contract";
  }
  return out;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function clampConfidence(raw: unknown): number {
  if (typeof raw !== "number" || !Number.isFinite(raw)) return 0;
  if (raw < 0) return 0;
  if (raw > 1) return 1;
  return raw;
}

function safeMessage(e: unknown): string {
  if (e instanceof Error) return e.message;
  try {
    return String(e);
  } catch {
    return "unknown";
  }
}
