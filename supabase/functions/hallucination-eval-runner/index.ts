// hallucination-eval-runner Edge Function
// -----------------------------------------------------------------------------
// Internal QA helper. Replicates the minimal Anthropic tool-use loop from
// eval/hallucination_detector.ts but runs it INSIDE Supabase Edge so it can
// use CLAUDE_API_KEY (which is not exposed to the laptop env).
//
// Auth: shared secret in X-Corpus-Secret header (matches CORPUS_EMBEDDER_SECRET).
//
// Wire format:
//   POST /functions/v1/hallucination-eval-runner
//   X-Corpus-Secret: <CORPUS_EMBEDDER_SECRET>
//   { "queries": SampleQuery[],
//     "model":   string  (optional, default claude-sonnet-4-6),
//     "max_tool_hops": number (optional, default 4),
//     "max_tokens":    number (optional, default 1024) }
//
//   SampleQuery = { id, query, category, lang, jurisdiction }
//
//   200 OK
//   { "results": Turn[],
//     "elapsed_ms": number,
//     "input_tokens": number,
//     "output_tokens": number }
//
//   Turn = {
//     q: SampleQuery,
//     hops: number,
//     tool_lookups: Array<{ tool_use_id, input, returned_chunks: [{act_slug, section_label, similarity}] }>,
//     final_text: string,
//     cites: Cite[],
//     false_cites: Cite[],
//     usage: { input_tokens, output_tokens },
//     error?: string
//   }
//
// Anti-abuse: queries cap at 10/request, total parallelism cap at 5 in-flight,
// max_tool_hops capped at 6.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const CORPUS_SECRET = Deno.env.get("CORPUS_EMBEDDER_SECRET") ?? "";
// ─── Internal Bearer JWT for the qa-corpus-search hop ─────────────────────────
//
// The runner-internal call to qa-corpus-search must carry a valid project JWT
// in the `Authorization` header — otherwise the Supabase Edge gateway rejects
// the request with `401 UNAUTHORIZED_INVALID_JWT_FORMAT` BEFORE the function
// code runs (qa-corpus-search itself authenticates via the X-QA-Secret header,
// so any valid project JWT — service-role OR anon — is fine for the gateway).
//
// FIX-WAVE 12 (2026-05-20): the 2026-05-19 eval reported 37.7% false-cite rate,
// but every one of the 93 tool calls in the JSONL showed
//   "error": "qa-corpus-search HTTP 401: Invalid JWT"
// Root cause: `SUPABASE_SERVICE_ROLE_KEY` was not set in this edge fn's
// secrets, so the previous code sent the literal header `Authorization: Bearer`
// (empty token) to the gateway → 401. The model received zero corpus chunks
// for every query and fell back to memorised statute knowledge — invalidating
// the 37.7% number entirely.
//
// Fix: prefer SUPABASE_SERVICE_ROLE_KEY, fall back to SUPABASE_ANON_KEY (set
// by Supabase platform automatically in every Edge fn deployment), and refuse
// to start if BOTH are missing so future evals fail loud instead of silently
// returning fabricated numbers.
//
// To re-deploy reproducibly:
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service_role_jwt>
//   supabase functions deploy hallucination-eval-runner
// (SUPABASE_URL and SUPABASE_ANON_KEY are auto-injected by the platform and
//  do not need to be set manually.)
const INTERNAL_BEARER_JWT =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_ANON_KEY") ??
  "";

const DEFAULT_MODEL = "claude-sonnet-4-6";
const DEFAULT_MAX_HOPS = 4;
const DEFAULT_MAX_TOKENS = 1024;
const HARD_QUERY_CAP = 10;
const HARD_HOP_CAP = 6;
const CONCURRENCY = 5;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-corpus-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function err(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}

/** Constant-time string compare — avoids a timing oracle on the corpus secret. */
function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

interface SampleQuery {
  id: string;
  query: string;
  category: string;
  lang: string;
  jurisdiction: string;
}

interface ToolUseBlock {
  type: "tool_use";
  id: string;
  name: string;
  input: { query?: string; jurisdiction?: string; specific_statute?: string };
}

interface TextBlock {
  type: "text";
  text: string;
}

type AssistantBlock = ToolUseBlock | TextBlock;

interface ToolLookupResult {
  tool_use_id: string;
  input: ToolUseBlock["input"];
  returned_chunks: Array<{
    act_slug: string;
    section_label: string | null;
    similarity: number;
  }>;
  error?: string;
}

interface Cite {
  raw: string;
  section: string;
  context: string;
}

interface Turn {
  q: SampleQuery;
  hops: number;
  tool_lookups: ToolLookupResult[];
  final_text: string;
  cites: Cite[];
  false_cites: Cite[];
  usage: { input_tokens: number; output_tokens: number };
  error?: string;
}

const LEGAL_LOOKUP_TOOL = {
  name: "legal_lookup",
  description:
    "Look up the current text of a specific statute paragraph from the Advocat legal corpus (FI, EE, EU). " +
    "Call BEFORE citing any specific paragraph. Returns top-5 most similar chunks with verbatim text, " +
    "section labels, source URL, and freshness metadata.",
  input_schema: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description:
          "Natural-language description of what to look up (e.g. 'menetetyn määräajan palauttaminen KHO', " +
          "'asianomistajan asema rikosasiassa', 'GDPR right to erasure').",
      },
      jurisdiction: {
        type: "string",
        enum: ["fi", "ee", "eu"],
        description: "Which corpus to search.",
      },
      specific_statute: {
        type: "string",
        description:
          "Optional. e.g. 'HOL §114', 'TLS §88', 'GDPR art 17' for higher precision.",
      },
    },
    required: ["query", "jurisdiction"],
  },
} as const;

const SYSTEM_PROMPT = `You are Advocat AI — a senior Finnish/Estonian/EU legal assistant.

## TOOL USE — legal_lookup (MANDATORY before any statute citation)

You have a 'legal_lookup' tool. CALL IT BEFORE citing any specific statute
paragraph content (e.g. HOL §114, TLS §88, GDPR art. 17). Not calling
it for a specific-paragraph citation is a defect.

Mandatory pattern:
  1. Identify which statute paragraph you are about to cite.
  2. Call legal_lookup({ query: '...', jurisdiction: 'fi'|'ee'|'eu' }).
  3. Read the returned current text.
  4. Quote/paraphrase based on THAT text — NEVER from memory.

Answer in 4-8 sentences. Cite statutes inline as "§N" (FI/EE) or "Article N" (EU).
Always prefer the jurisdiction implied by the question.`;

// ─── Cite extraction (verbatim from eval/hallucination_detector.ts) ────────
const CITE_PATTERNS: Array<{ re: RegExp; group: number }> = [
  { re: /§\s*([A-ZÄÖÕÜŠŽ]{2,8}\s+\d+:\d+)/g, group: 1 },
  { re: /§\s*(\d+(?::\d+)?)/g, group: 1 },
  { re: /\b(?:Article|art\.?)\s+(\d+(?:\(\d+\))?)/gi, group: 1 },
];

function extractCites(text: string): Cite[] {
  const out: Cite[] = [];
  const seen = new Set<string>();
  for (const { re, group } of CITE_PATTERNS) {
    re.lastIndex = 0;
    let m: RegExpExecArray | null;
    while ((m = re.exec(text)) !== null) {
      const raw = m[0];
      const section = m[group].replace(/\s+/g, " ").trim();
      const key = section.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      const start = Math.max(0, m.index - 30);
      const end = Math.min(text.length, m.index + raw.length + 30);
      out.push({ raw, section, context: text.slice(start, end) });
    }
  }
  return out;
}

function sectionFromChunk(label: string | null): string {
  if (!label) return "";
  const stripped = label.replace(/§/g, "").trim();
  const m = stripped.match(/(\d+:\d+|\d+(?:¹|²|³)?)\s*$/);
  if (m) return m[1];
  return stripped;
}

function citationCovered(c: Cite, lookups: ToolLookupResult[]): boolean {
  const target = c.section.toLowerCase().replace(/\s+/g, "");
  const targetNum = target.match(/(\d+(?::\d+)?)/)?.[1] ?? target;
  for (const lk of lookups) {
    const ss = (lk.input.specific_statute ?? "").toLowerCase();
    if (ss && (ss.includes(target) || ss.includes(targetNum))) return true;
    for (const ch of lk.returned_chunks) {
      const lab = sectionFromChunk(ch.section_label).toLowerCase();
      if (!lab) continue;
      if (lab === target || lab === targetNum) return true;
      if (lab.endsWith(":" + targetNum)) return true;
      if (target.endsWith(":" + lab)) return true;
    }
  }
  return false;
}

// ─── Internal tool exec: qa-corpus-search ──────────────────────────────────
async function execLegalLookup(
  input: ToolUseBlock["input"],
): Promise<{ chunks: ToolLookupResult["returned_chunks"]; error?: string }> {
  const query =
    (input.specific_statute ? input.specific_statute + " — " : "") +
    (input.query ?? "");
  const jurisdiction = input.jurisdiction ?? "fi";
  if (!["fi", "ee", "eu"].includes(jurisdiction)) {
    return { chunks: [], error: `bad jurisdiction: ${jurisdiction}` };
  }

  const resp = await fetch(`${SUPABASE_URL}/functions/v1/qa-corpus-search`, {
    method: "POST",
    headers: {
      // FIX-WAVE 12: must be a non-empty, project-valid JWT. The Edge gateway
      // rejects an empty Bearer with "Invalid JWT" BEFORE the target function
      // runs — that's the bug that invalidated the 2026-05-19 eval. See the
      // INTERNAL_BEARER_JWT block at the top of this file for details.
      "Authorization": `Bearer ${INTERNAL_BEARER_JWT}`,
      "X-QA-Secret": CORPUS_SECRET,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      query,
      jurisdiction,
      top_k: 5,
      threshold: -1,
    }),
  });
  if (!resp.ok) {
    const t = await resp.text().catch(() => "");
    return {
      chunks: [],
      error: `qa-corpus-search HTTP ${resp.status}: ${t.slice(0, 160)}`,
    };
  }
  const j = await resp.json() as {
    rows?: Array<{
      act_slug: string;
      section_label: string | null;
      similarity: number;
    }>;
  };
  return {
    chunks: (j.rows ?? []).map((r) => ({
      act_slug: r.act_slug,
      section_label: r.section_label,
      similarity: r.similarity ?? 0,
    })),
  };
}

function fmtToolResult(chunks: ToolLookupResult["returned_chunks"]): string {
  if (chunks.length === 0) return "No matches in corpus.";
  return chunks
    .map(
      (c, i) =>
        `${i + 1}. ${c.act_slug} §${c.section_label ?? "?"} (sim=${
          c.similarity.toFixed(3)
        })`,
    )
    .join("\n");
}

// ─── Anthropic call ────────────────────────────────────────────────────────
async function callAnthropic(
  messages: unknown[],
  model: string,
  maxTokens: number,
): Promise<{
  ok: boolean;
  content?: AssistantBlock[];
  stop_reason?: string;
  usage?: { input_tokens: number; output_tokens: number };
  error?: string;
}> {
  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": CLAUDE_API_KEY,
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      system: SYSTEM_PROMPT,
      tools: [LEGAL_LOOKUP_TOOL],
      messages,
    }),
  });
  if (!resp.ok) {
    const t = await resp.text().catch(() => "");
    return {
      ok: false,
      error: `anthropic HTTP ${resp.status}: ${t.slice(0, 280)}`,
    };
  }
  const j = await resp.json() as {
    content?: AssistantBlock[];
    stop_reason?: string;
    usage?: { input_tokens?: number; output_tokens?: number };
  };
  return {
    ok: true,
    content: j.content ?? [],
    stop_reason: j.stop_reason,
    usage: {
      input_tokens: j.usage?.input_tokens ?? 0,
      output_tokens: j.usage?.output_tokens ?? 0,
    },
  };
}

// ─── Per-query run ─────────────────────────────────────────────────────────
async function runOne(
  q: SampleQuery,
  model: string,
  maxHops: number,
  maxTokens: number,
): Promise<Turn> {
  const turn: Turn = {
    q,
    hops: 0,
    tool_lookups: [],
    final_text: "",
    cites: [],
    false_cites: [],
    usage: { input_tokens: 0, output_tokens: 0 },
  };
  const messages: unknown[] = [{ role: "user", content: q.query }];

  let lastBlocks: AssistantBlock[] = [];
  for (let hop = 0; hop < maxHops; hop++) {
    turn.hops = hop + 1;
    const resp = await callAnthropic(messages, model, maxTokens);
    if (!resp.ok) {
      turn.error = resp.error;
      return turn;
    }
    const content = resp.content ?? [];
    lastBlocks = content;
    if (resp.usage) {
      turn.usage.input_tokens += resp.usage.input_tokens;
      turn.usage.output_tokens += resp.usage.output_tokens;
    }

    const toolUses = content.filter(
      (b): b is ToolUseBlock => b.type === "tool_use",
    );
    if (toolUses.length === 0 || resp.stop_reason === "end_turn") {
      turn.final_text = content
        .filter((b): b is TextBlock => b.type === "text")
        .map((b) => b.text)
        .join("\n\n");
      break;
    }

    const toolResults: Array<{
      type: "tool_result";
      tool_use_id: string;
      content: string;
      is_error?: boolean;
    }> = [];
    for (const tu of toolUses) {
      const r = await execLegalLookup(tu.input);
      turn.tool_lookups.push({
        tool_use_id: tu.id,
        input: tu.input,
        returned_chunks: r.chunks,
        error: r.error,
      });
      toolResults.push({
        type: "tool_result",
        tool_use_id: tu.id,
        content: r.error ? `Error: ${r.error}` : fmtToolResult(r.chunks),
        is_error: !!r.error,
      });
    }
    messages.push({ role: "assistant", content });
    messages.push({ role: "user", content: toolResults });
  }

  if (!turn.final_text && lastBlocks.length > 0) {
    turn.final_text = lastBlocks
      .filter((b): b is TextBlock => b.type === "text")
      .map((b) => b.text)
      .join("\n\n");
  }

  turn.cites = extractCites(turn.final_text);
  turn.false_cites = turn.cites.filter(
    (c) => !citationCovered(c, turn.tool_lookups),
  );
  return turn;
}

// ─── Bounded-concurrency runner ────────────────────────────────────────────
async function runWithConcurrency<T, R>(
  items: T[],
  worker: (item: T, idx: number) => Promise<R>,
  concurrency: number,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let cursor = 0;
  async function pump() {
    while (true) {
      const i = cursor++;
      if (i >= items.length) return;
      results[i] = await worker(items[i], i);
    }
  }
  const workers = Array.from(
    { length: Math.min(concurrency, items.length) },
    () => pump(),
  );
  await Promise.all(workers);
  return results;
}

// ─── HTTP handler ──────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") return err("Method not allowed", 405);

  const secret = req.headers.get("x-corpus-secret") ?? "";
  if (!CORPUS_SECRET || !timingSafeEqualStr(secret, CORPUS_SECRET)) {
    return err("Unauthorized", 401);
  }
  if (!CLAUDE_API_KEY) return err("CLAUDE_API_KEY not configured", 500);
  // FIX-WAVE 12: fail loud if neither service-role nor anon JWT is available
  // — silently sending Bearer "" was the root cause of the 2026-05-19 eval
  // measuring "memorised § knowledge" instead of "RAG-grounded § accuracy".
  if (!SUPABASE_URL || !INTERNAL_BEARER_JWT) {
    return err(
      "Supabase env not configured (need SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY)",
      500,
    );
  }

  let body: {
    queries?: SampleQuery[];
    model?: string;
    max_tool_hops?: number;
    max_tokens?: number;
  };
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON body", 400);
  }

  const queries = Array.isArray(body.queries) ? body.queries : [];
  if (queries.length === 0) return err("queries[] required", 400);
  if (queries.length > HARD_QUERY_CAP) {
    return err(`queries[] too many (max ${HARD_QUERY_CAP} per request)`, 400);
  }
  for (const q of queries) {
    if (
      !q || typeof q.id !== "string" || typeof q.query !== "string" ||
      typeof q.jurisdiction !== "string"
    ) {
      return err("Invalid query shape (need id, query, jurisdiction)", 400);
    }
  }

  const model = typeof body.model === "string" && body.model
    ? body.model
    : DEFAULT_MODEL;
  const maxHops = Math.min(
    HARD_HOP_CAP,
    typeof body.max_tool_hops === "number" && body.max_tool_hops > 0
      ? Math.floor(body.max_tool_hops)
      : DEFAULT_MAX_HOPS,
  );
  const maxTokens =
    typeof body.max_tokens === "number" && body.max_tokens > 0 &&
      body.max_tokens <= 4096
      ? Math.floor(body.max_tokens)
      : DEFAULT_MAX_TOKENS;

  const tStart = performance.now();

  const turns = await runWithConcurrency(
    queries,
    async (q) => {
      try {
        return await runOne(q, model, maxHops, maxTokens);
      } catch (e) {
        return {
          q,
          hops: 0,
          tool_lookups: [],
          final_text: "",
          cites: [],
          false_cites: [],
          usage: { input_tokens: 0, output_tokens: 0 },
          error: String(e),
        } satisfies Turn;
      }
    },
    CONCURRENCY,
  );

  const inputTokens = turns.reduce((a, t) => a + t.usage.input_tokens, 0);
  const outputTokens = turns.reduce((a, t) => a + t.usage.output_tokens, 0);

  return new Response(
    JSON.stringify({
      results: turns,
      elapsed_ms: Math.round(performance.now() - tStart),
      input_tokens: inputTokens,
      output_tokens: outputTokens,
      model,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
