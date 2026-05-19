// draft-ai-revise/handler.ts — pure business logic for AI revision.
// -----------------------------------------------------------------------------
// Split from index.ts so tests can inject fakes for Anthropic / DB. The HTTP
// layer (index.ts) is a thin shim around `runDraftRevise`.
//
// Pkg 7 Drafting Studio MVP — given a selected text fragment, an optional
// user instruction, and surrounding context, ask Claude Sonnet to revise
// the fragment while preserving legal meaning and tonal consistency.
//
// Contract:
//   Input  : { draft_id, selected_text, context?, instruction?, language? }
//   Output : { revised_text, explanation, changes_made: string[] }
//
// Errors are returned as `{ kind: "error", status, body }` so the HTTP shim
// can shape the response without duplicating CORS/JSON wiring.
// -----------------------------------------------------------------------------

// ─── Tunables ───────────────────────────────────────────────────────────────

/** Hard cap on selected text length — anything longer should be chunked by
 *  the client. Keeps latency predictable and avoids Anthropic context bloat. */
export const MAX_SELECTED_CHARS = 8_000;

/** Hard cap on surrounding context. The client should supply ~2 paragraphs
 *  above + below the selection. We trim to keep prompts cheap. */
export const MAX_CONTEXT_CHARS = 4_000;

/** Hard cap on the user-supplied instruction. Anything longer is truncated. */
export const MAX_INSTRUCTION_CHARS = 600;

/** Claude model used for revisions. Sonnet is cheap for short edits and
 *  preserves legal tone better than Haiku in our benches. */
export const REVISE_MODEL = "claude-sonnet-4-6";

/** Anthropic max_tokens for the revision response. Keeps the editor snappy. */
export const REVISE_MAX_TOKENS = 4_096;

// ─── Public contracts ───────────────────────────────────────────────────────

export interface DraftReviseRequest {
  draft_id: string;
  selected_text: string;
  /** Surrounding context (paragraphs around the selection). Optional but
   *  strongly recommended — preserves tonal consistency. */
  context?: string;
  /** Optional plain-language instruction ("Make it more formal", "Shorten",
   *  …). Defaults to a generic "improve clarity and legal precision". */
  instruction?: string;
  /** ISO-639-1 hint. If absent, the model auto-detects from the input. */
  language?: string;
}

export interface DraftReviseSuccess {
  kind: "success";
  status: 200;
  body: {
    revised_text: string;
    explanation: string;
    changes_made: string[];
  };
}

export interface DraftReviseError {
  kind: "error";
  status: number;
  body: { error: string };
}

export type DraftReviseResult = DraftReviseSuccess | DraftReviseError;

// ─── Anthropic client surface (injectable for tests) ────────────────────────

export interface AnthropicCaller {
  (req: AnthropicRequest): Promise<AnthropicResponse>;
}

export interface AnthropicRequest {
  model: string;
  max_tokens: number;
  system: string;
  messages: Array<{ role: "user" | "assistant"; content: string }>;
}

export interface AnthropicResponse {
  content: Array<{ type: string; text?: string }>;
}

// ─── DB client surface (injectable for tests) ───────────────────────────────

export interface DraftDbClient {
  /** Returns true iff the draft exists AND is owned by `userId`. The handler
   *  refuses to revise drafts the caller does not own (defence-in-depth,
   *  even though RLS already protects the row). */
  isOwner(draftId: string, userId: string): Promise<boolean>;
}

// ─── Prompt builder ─────────────────────────────────────────────────────────

const DEFAULT_INSTRUCTION =
  "Improve clarity and legal precision without changing the underlying meaning.";

/** Builds the system prompt that frames the model as a legal-draft editor.
 *  Kept separate so we can unit-test the prompt shape independently. */
export function buildReviseSystemPrompt(opts: { language?: string }): string {
  const lang = opts.language?.trim();
  const langClause = lang
    ? `The draft is written in language code "${lang}". Respond in the same language.`
    : "Respond in the same language as the selected text.";

  return [
    "You are a careful legal editor revising a fragment of a legal draft.",
    "",
    "Rules — apply ALL:",
    "1. Preserve the legal meaning. Do not add new claims, dates, sums, or",
    "   citations. Do not remove statutory references or named parties.",
    "2. Preserve tonal consistency with the surrounding context. If the",
    "   draft is formal, stay formal; if it is conversational, stay so.",
    "3. Apply the user's instruction precisely. If no instruction is given,",
    "   default to improving clarity and legal precision.",
    "4. Output ONLY a JSON object with this exact shape:",
    "   {",
    '     "revised_text": "<the revised fragment, plain markdown>",',
    '     "explanation": "<one short sentence about WHAT you changed and WHY>",',
    '     "changes_made": ["<change 1>", "<change 2>", ...]',
    "   }",
    "5. The `revised_text` must be a drop-in replacement for the selection —",
    "   do not include surrounding context, headings outside the selection,",
    "   or commentary. Keep markdown formatting (bold, lists, links) when",
    "   present in the input.",
    "6. `changes_made` lists 1-5 concrete edits as short bullets. If you",
    "   made no change (e.g. the selection is already optimal), return an",
    "   empty array and set revised_text equal to the input.",
    "",
    langClause,
  ].join("\n");
}

/** Builds the user-turn payload combining context + selection + instruction. */
export function buildReviseUserMessage(req: DraftReviseRequest): string {
  const ctx = (req.context ?? "").slice(0, MAX_CONTEXT_CHARS).trim();
  const sel = req.selected_text.slice(0, MAX_SELECTED_CHARS);
  const inst = (req.instruction ?? "").slice(0, MAX_INSTRUCTION_CHARS).trim() ||
    DEFAULT_INSTRUCTION;

  const parts: string[] = [];
  parts.push(`User instruction: ${inst}`);
  if (ctx) {
    parts.push("");
    parts.push("Surrounding context (do not include in revised_text):");
    parts.push("---");
    parts.push(ctx);
    parts.push("---");
  }
  parts.push("");
  parts.push("Selection to revise:");
  parts.push("---");
  parts.push(sel);
  parts.push("---");
  parts.push("");
  parts.push("Return ONLY the JSON object specified in the system prompt.");
  return parts.join("\n");
}

// ─── Response parser ────────────────────────────────────────────────────────

/** Extracts the JSON object from the Anthropic response. Tolerates a leading
 *  ```json fence or stray prose — we scan for the first '{' and the matching
 *  closing brace. Returns null if no valid object can be parsed. */
export function parseReviseJson(raw: string): {
  revised_text: string;
  explanation: string;
  changes_made: string[];
} | null {
  const trimmed = raw.trim();
  // Fast path: pure JSON.
  let candidate = trimmed;
  // Strip ```json fence if present.
  const fenceMatch = /^```(?:json)?\s*([\s\S]*?)\s*```$/m.exec(trimmed);
  if (fenceMatch) candidate = fenceMatch[1].trim();
  // Scan for first '{' and the matching '}' using brace depth.
  const start = candidate.indexOf("{");
  if (start < 0) return null;
  let depth = 0;
  let end = -1;
  for (let i = start; i < candidate.length; i++) {
    const ch = candidate[i];
    if (ch === "{") depth++;
    else if (ch === "}") {
      depth--;
      if (depth === 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return null;
  const body = candidate.slice(start, end + 1);
  try {
    const obj = JSON.parse(body) as Record<string, unknown>;
    const revised = typeof obj.revised_text === "string" ? obj.revised_text : null;
    const explanation =
      typeof obj.explanation === "string" ? obj.explanation : "";
    const changesRaw = Array.isArray(obj.changes_made) ? obj.changes_made : [];
    const changes = changesRaw.filter((x): x is string => typeof x === "string");
    if (revised === null) return null;
    return {
      revised_text: revised,
      explanation,
      changes_made: changes,
    };
  } catch (_e) {
    return null;
  }
}

// ─── Input validation ───────────────────────────────────────────────────────

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function validateRequest(
  body: unknown,
): { ok: true; req: DraftReviseRequest } | { ok: false; error: string } {
  if (!body || typeof body !== "object") {
    return { ok: false, error: "Request body must be a JSON object" };
  }
  const b = body as Record<string, unknown>;

  if (typeof b.draft_id !== "string" || !UUID_RE.test(b.draft_id)) {
    return { ok: false, error: "draft_id must be a valid UUID" };
  }
  if (typeof b.selected_text !== "string") {
    return { ok: false, error: "selected_text is required" };
  }
  const sel = b.selected_text.trim();
  if (sel.length === 0) {
    return { ok: false, error: "selected_text must not be empty" };
  }
  if (sel.length > MAX_SELECTED_CHARS) {
    return {
      ok: false,
      error: `selected_text exceeds ${MAX_SELECTED_CHARS} chars`,
    };
  }

  const req: DraftReviseRequest = {
    draft_id: b.draft_id,
    selected_text: b.selected_text,
  };
  if (typeof b.context === "string") req.context = b.context;
  if (typeof b.instruction === "string") req.instruction = b.instruction;
  if (typeof b.language === "string") req.language = b.language;

  return { ok: true, req };
}

// ─── Orchestrator ───────────────────────────────────────────────────────────

export interface RunReviseDeps {
  db: DraftDbClient;
  callAnthropic: AnthropicCaller;
}

/** Top-level handler. The HTTP shim shapes status codes from `.status` and
 *  the body from `.body` — see index.ts. */
export async function runDraftRevise(
  rawBody: unknown,
  userId: string,
  deps: RunReviseDeps,
): Promise<DraftReviseResult> {
  const validated = validateRequest(rawBody);
  if (!validated.ok) {
    return {
      kind: "error",
      status: 400,
      body: { error: validated.error },
    };
  }
  const req = validated.req;

  // Ownership check (defence in depth — RLS would also stop a cross-user
  // read, but we want to fail fast with a clear 403).
  const owns = await deps.db.isOwner(req.draft_id, userId);
  if (!owns) {
    return {
      kind: "error",
      status: 403,
      body: { error: "Draft not found or not yours" },
    };
  }

  const system = buildReviseSystemPrompt({ language: req.language });
  const userMsg = buildReviseUserMessage(req);

  let resp: AnthropicResponse;
  try {
    resp = await deps.callAnthropic({
      model: REVISE_MODEL,
      max_tokens: REVISE_MAX_TOKENS,
      system,
      messages: [{ role: "user", content: userMsg }],
    });
  } catch (e) {
    return {
      kind: "error",
      status: 503,
      body: { error: `AI backend error: ${String(e)}` },
    };
  }

  // Concatenate all text blocks (Anthropic may chunk).
  const raw = resp.content
    .filter((c) => c.type === "text" && typeof c.text === "string")
    .map((c) => c.text!)
    .join("");
  if (!raw.trim()) {
    return {
      kind: "error",
      status: 502,
      body: { error: "AI returned empty response" },
    };
  }

  const parsed = parseReviseJson(raw);
  if (!parsed) {
    return {
      kind: "error",
      status: 502,
      body: { error: "AI returned malformed JSON" },
    };
  }

  return {
    kind: "success",
    status: 200,
    body: {
      revised_text: parsed.revised_text,
      explanation: parsed.explanation,
      changes_made: parsed.changes_made,
    },
  };
}
