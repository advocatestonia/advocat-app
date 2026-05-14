// credit_fallback.ts — Anthropic $0 balance graceful degradation.
// -----------------------------------------------------------------------------
// When Anthropic returns 400 Bad Request with an error message that contains
// "credit balance" (the exact phrasing Anthropic uses when the org wallet hits
// $0), the proxy can no longer generate a chat reply but it can still surface
// real legal text via the law-search corpus + cases_citing RPCs.
//
// This module implements:
//   1. `isCreditBalanceError(status, body)` — pure classifier. Returns true
//      only when status===400 AND the body string contains the marker
//      substring. We match case-insensitively to be robust against
//      Anthropic's occasional capitalisation changes.
//   2. `buildRagOnlyResponse(query, jurisdiction, deps)` — fetches the top-K
//      law_search rows + optional cases_citing rows and formats them as a
//      plain-text reply with a leading "AI generation temporarily unavailable"
//      banner. Returned in Anthropic message shape so the Flutter SSE / JSON
//      client renderers do not need any wire-format changes.
//   3. `buildRagOnlyJsonResponse` / `buildRagOnlySseResponse` — Response
//      builders that mirror the happy-path content type expected by each
//      branch in claude-proxy/index.ts. Both ship status 200 (not 5xx) because
//      this is a graceful degradation, not an outage — the client should
//      render the content, not show a retry banner.
//
// Cost: one OpenAI embedding call (~$0.0001) + one Supabase RPC. No Anthropic
// call. Safe to invoke when the Anthropic wallet is empty.
// -----------------------------------------------------------------------------

import { embedQuery } from "../law-search/embed.ts";

// =============================================================================
// 1. Credit-error classifier
// =============================================================================

/** Substring Anthropic always includes in the 400 body when the org wallet
 *  is at $0. Lower-cased so the matcher is case-insensitive. The exact
 *  current phrasing is:
 *
 *    "Your credit balance is too low to access the Anthropic API"
 *
 *  We match on "credit balance" to be resilient to wording tweaks. */
const CREDIT_BALANCE_MARKER = "credit balance";

/** Returns true iff the upstream looks like an Anthropic $0-wallet 400. */
export function isCreditBalanceError(status: number, body: string): boolean {
  if (status !== 400) return false;
  if (!body) return false;
  return body.toLowerCase().includes(CREDIT_BALANCE_MARKER);
}

// =============================================================================
// 2. RAG-only response builder
// =============================================================================

/** Whitelisted jurisdiction codes the fallback understands. Matches the
 *  upstream `law_search` RPC signature. */
const SUPPORTED_JURISDICTIONS = new Set(["FI", "EE", "EU", "RU", "DE"]);

/** Jurisdiction → lang hint passed to law_search. The RPC widens to eu_*
 *  rows for EU regardless, but a lang hint biases the embedding match toward
 *  the right corpus partition. */
const JURISDICTION_TO_LANG: Record<string, string> = {
  FI: "fi",
  EE: "et",
  EU: "en",
  DE: "en",
  RU: "ru",
};

/** Maximum number of statute chunks to render in the fallback reply. Three
 *  keeps the body short enough that the Flutter chat bubble doesn't scroll
 *  past one screen. */
const TOP_K = 3;

/** Per-chunk snippet cap (chars). Matches legal_lookup's truncation so users
 *  see roughly the same depth of statute text as the tool-use path. */
const SNIPPET_MAX_CHARS = 600;

export interface RagChunk {
  act_slug: string;
  act_name?: string | null;
  paragraph: string;
  title?: string | null;
  body: string;
  source_url?: string | null;
  similarity?: number;
}

export interface CaseCitingRow {
  case_number: string;
  court: string;
  decided_at?: string | null;
  key_holding?: string | null;
}

export interface RagFallbackDeps {
  /** OpenAI embedding fn (uses OPENAI_API_KEY — separate from Anthropic, so
   *  this works even when Anthropic is at $0). */
  embed: (q: string) => Promise<{ embedding: number[]; tokens: number } | null>;
  /** Supabase RPC wrapper for `law_search` (positional matches law-search/index.ts). */
  lawSearch: (params: {
    query_embedding: number[];
    query_lang: string;
    match_count: number;
    similarity_threshold: number;
    query_jurisdiction: string | null;
  }) => Promise<RagChunk[] | null>;
  /** Optional `cases_citing` RPC — when present, decorates the top hit with
   *  related court decisions. Failure is swallowed. */
  casesCiting?: (params: {
    act_slug: string;
    section: string;
  }) => Promise<CaseCitingRow[] | null>;
}

export interface RagFallbackOptions {
  /** ISO-639 jurisdiction code. Accepts mixed case; uppercased internally. */
  jurisdiction?: string | null;
  /** Override top-K. */
  topK?: number;
}

export interface RagFallbackResult {
  /** Plain-text reply body, ready to embed in Anthropic content blocks. */
  text: string;
  /** Number of statute chunks actually rendered (≤ topK). */
  chunkCount: number;
  /** Number of cases_citing rows rendered. */
  caseCount: number;
  /** Was the request degraded due to no corpus hit? */
  emptyCorpus: boolean;
}

/** Build the plain-text RAG-only reply. Pure-ish: side-effects limited to the
 *  injected dependencies (embed + RPC). Never throws — errors collapse to an
 *  apologetic "no sources found" body so the caller can always ship 200. */
export async function buildRagOnlyResponse(
  query: string,
  deps: RagFallbackDeps,
  options: RagFallbackOptions = {},
): Promise<RagFallbackResult> {
  const trimmed = (query ?? "").trim();
  const topK = options.topK ?? TOP_K;
  const jurisdictionRaw = (options.jurisdiction ?? "FI").toUpperCase();
  const jurisdiction = SUPPORTED_JURISDICTIONS.has(jurisdictionRaw)
    ? jurisdictionRaw
    : "FI";

  if (!trimmed) {
    return {
      text: BANNER + "\n\n" + EMPTY_QUERY_FOOTER,
      chunkCount: 0,
      caseCount: 0,
      emptyCorpus: true,
    };
  }

  // Embed via OpenAI (separate budget — unaffected by the Anthropic $0).
  let embedded: Awaited<ReturnType<typeof deps.embed>> = null;
  try {
    embedded = await deps.embed(trimmed);
  } catch (err) {
    console.warn(`credit_fallback: embed threw ${String(err)}`);
  }
  if (!embedded) {
    return {
      text: BANNER + "\n\n" + NO_EMBED_FOOTER,
      chunkCount: 0,
      caseCount: 0,
      emptyCorpus: true,
    };
  }

  // RPC against law_search. Failures swallow → empty corpus message.
  let rows: RagChunk[] | null = null;
  try {
    rows = await deps.lawSearch({
      query_embedding: embedded.embedding,
      query_lang: JURISDICTION_TO_LANG[jurisdiction] ?? "fi",
      match_count: topK,
      similarity_threshold: 0.5,
      query_jurisdiction: jurisdiction,
    });
  } catch (err) {
    console.warn(`credit_fallback: law_search RPC threw ${String(err)}`);
  }
  if (!rows || rows.length === 0) {
    return {
      text: BANNER + "\n\n" + NO_CORPUS_FOOTER,
      chunkCount: 0,
      caseCount: 0,
      emptyCorpus: true,
    };
  }

  // Optional enrichment: cases_citing on the top hit only (kept short to
  // respect the 3-screen body cap).
  const top = rows[0];
  let cases: CaseCitingRow[] = [];
  if (deps.casesCiting && top) {
    try {
      const fetched = await deps.casesCiting({
        act_slug: top.act_slug,
        section: top.paragraph,
      });
      if (Array.isArray(fetched)) cases = fetched.slice(0, 2);
    } catch (err) {
      console.warn(`credit_fallback: cases_citing threw ${String(err)}`);
    }
  }

  return {
    text: formatRagBody(rows.slice(0, topK), cases),
    chunkCount: Math.min(rows.length, topK),
    caseCount: cases.length,
    emptyCorpus: false,
  };
}

// =============================================================================
// 3. Response builders (JSON + SSE)
// =============================================================================

/** Anthropic Messages API JSON shape — kept minimal but sufficient for the
 *  Flutter chat parser. */
export function buildRagOnlyJsonResponse(
  result: RagFallbackResult,
  options: { messageId?: string | null } = {},
): Response {
  const body: Record<string, unknown> = {
    id: `msg_fallback_${Date.now()}`,
    type: "message",
    role: "assistant",
    model: "rag-only-fallback",
    content: [{ type: "text", text: result.text }],
    stop_reason: "end_turn",
    stop_sequence: null,
    usage: { input_tokens: 0, output_tokens: 0 },
    citations: [],
    model_used: "rag-only-fallback",
    fallback_reason: "anthropic_credit_exhausted",
    rag_chunk_count: result.chunkCount,
  };
  if (options.messageId) body.message_id = options.messageId;

  return new Response(JSON.stringify(body), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "X-Advocat-Model-Used": "rag-only-fallback",
    },
  });
}

/** Synthetic SSE wrap so callers that sent stream:true get the same
 *  Anthropic-shaped event sequence the Flutter SSE parser expects:
 *    message_start → content_block_start → content_block_delta(*)
 *    → content_block_stop → message_delta → message_stop. */
export function buildRagOnlySseResponse(
  result: RagFallbackResult,
  options: { messageId?: string | null } = {},
): Response {
  const messageId = options.messageId ?? `msg_fallback_${Date.now()}`;
  const text = result.text;
  const encoder = new TextEncoder();

  const events: string[] = [];
  const emit = (event: string, data: Record<string, unknown>) => {
    events.push(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };

  emit("message_start", {
    type: "message_start",
    message: {
      id: messageId,
      type: "message",
      role: "assistant",
      content: [],
      model: "rag-only-fallback",
      stop_reason: null,
      stop_sequence: null,
      usage: { input_tokens: 0, output_tokens: 0 },
    },
  });
  emit("content_block_start", {
    type: "content_block_start",
    index: 0,
    content_block: { type: "text", text: "" },
  });
  emit("content_block_delta", {
    type: "content_block_delta",
    index: 0,
    delta: { type: "text_delta", text },
  });
  emit("content_block_stop", { type: "content_block_stop", index: 0 });
  emit("message_delta", {
    type: "message_delta",
    delta: { stop_reason: "end_turn", stop_sequence: null },
    usage: { output_tokens: 0 },
  });
  emit("message_stop", { type: "message_stop" });
  emit("citations", { citations: [], message_id: messageId });

  return new Response(encoder.encode(events.join("")), {
    status: 200,
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "X-Accel-Buffering": "no",
      "X-Advocat-Model-Used": "rag-only-fallback",
    },
  });
}

// =============================================================================
// 4. OpenAI embed factory + Supabase RPC factory
// =============================================================================
//
// These adapter factories keep the heavy `createClient` call out of unit tests
// — pass the factory outputs as `deps` and the test can substitute pure
// in-memory fakes.

export function buildEmbedFn(openaiApiKey: string) {
  return async (q: string) => {
    return await embedQuery(q, { apiKey: openaiApiKey, timeoutMs: 5000 });
  };
}

// =============================================================================
// 5. Banner + body formatting
// =============================================================================

const BANNER =
  "⚠️ AI generation temporarily unavailable.\n" +
  "Näytämme aiheeseen liittyvät säädöstekstit suoraan korpuksesta.";

const EMPTY_QUERY_FOOTER =
  "Anna kysymys uudelleen muutaman tunnin kuluttua, kun AI on jälleen käytettävissä.";

const NO_EMBED_FOOTER =
  "Hakukoneeseen ei saatu yhteyttä juuri nyt. Yritä uudelleen muutaman minuutin kuluttua.";

const NO_CORPUS_FOOTER =
  "Korpuksesta ei löytynyt vastaavia säädöstekstejä. " +
  "Yritä uudelleen muutaman tunnin kuluttua, kun AI on jälleen käytettävissä.";

const RESTORE_FOOTER =
  "Please try again in a few hours when AI generation is restored.";

function formatRagBody(
  rows: RagChunk[],
  cases: CaseCitingRow[],
): string {
  const parts: string[] = [BANNER, "", "Relevant legal sources for your query:"];
  for (const r of rows) {
    const slug = (r.act_slug || "").toUpperCase();
    const para = r.paragraph || "";
    const heading = `📖 [${slug} §${para}]`;
    const title = r.title ? ` — ${r.title}` : (r.act_name ? ` — ${r.act_name}` : "");
    const snippet = (r.body || "").slice(0, SNIPPET_MAX_CHARS);
    const source = r.source_url ? `\nSource: ${r.source_url}` : "";
    parts.push("", heading + title, snippet + source);
  }
  if (cases.length > 0) {
    parts.push("", "⚖️ Related court cases:");
    for (const c of cases) {
      const date = (c.decided_at ?? "").slice(0, 10);
      const holding = (c.key_holding ?? "").slice(0, 160);
      parts.push(
        `• ${c.court} ${c.case_number}${date ? ` (${date})` : ""}${
          holding ? ` — ${holding}` : ""
        }`,
      );
    }
  }
  parts.push("", RESTORE_FOOTER);
  return parts.join("\n");
}
