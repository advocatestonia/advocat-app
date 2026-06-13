// corrections_retriever.ts — retrieve + inject + self-correct.
// ----------------------------------------------------------------------------
// Three responsibilities:
//   1. embedText            — OpenAI text-embedding-3-small wrapper.
//   2. retrieveCorrections  — call match_corrections RPC for top-N similar
//                             past mistakes given the current question.
//   3. formatCorrectionsBlock — render the retrieved rows as a
//                             <learned_corrections> block, capped at 4 KB.
//   4. selfCorrectionScan   — final-output scan that flags drafts repeating
//                             a known wrong_advice substring.
//
// Cap: the injection block must NOT exceed CORRECTIONS_BLOCK_MAX_BYTES so we
// don't blow the system-prompt budget (50 KB cap in claude-proxy, see
// lesson_50kb_system_prompt_cap.md). 4 KB leaves headroom for legal corpus
// + memory + active case context.
// ----------------------------------------------------------------------------

export const CORRECTIONS_BLOCK_MAX_BYTES = 4 * 1024;
// 2026-05-14 (lesson_corrections_retrieval_debug.md): lowered from 0.75
// because cross-language queries (RU/EE user → FI/EN correction row)
// produce cosine similarities ~0.45-0.55 with text-embedding-3-small.
// 0.45 still cleanly rejects unrelated content (typically <0.40) but
// captures the cross-language matches the corpus was designed for.
// Same-language queries score >0.85, well above any reasonable noise
// floor, so we lose no precision in the monolingual case.
export const DEFAULT_SIMILARITY_THRESHOLD = 0.45;
export const DEFAULT_TOP_K = 3;

import { pseudonymize } from "./llm_egress/pseudonymizer.ts";

const OPENAI_URL = "https://api.openai.com/v1/embeddings";
const OPENAI_MODEL = "text-embedding-3-small";

// ─── Types ──────────────────────────────────────────────────────────────────

export interface CorrectionRow {
  id: string;
  question: string;
  wrong_advice: string;
  correct_answer: string;
  why_wrong: string;
  jurisdiction: string | null;
  case_type: string | null;
  severity: string | null;
  similarity: number;
}

export interface EmbedTextOpts {
  text: string;
  openaiApiKey: string;
  /** Optional fetch override for tests. */
  fetcher?: typeof fetch;
}

export interface RetrieveCorrectionsOpts {
  question: string;
  jurisdiction?: string | null;
  threshold?: number;
  topK?: number;
  supabaseUrl: string;
  serviceRoleKey: string;
  openaiApiKey?: string;
  /** Injection seam for tests — bypasses OpenAI + Supabase calls. */
  retriever?: SimilarityRetriever;
}

/** Signature of the similarity retriever — tests can inject a stub. */
export type SimilarityRetriever = (req: {
  questionEmbedding: number[];
  jurisdiction?: string | null;
  threshold: number;
  topK: number;
}) => Promise<CorrectionRow[]>;

// ─── 1. Embedding ───────────────────────────────────────────────────────────

/**
 * Call OpenAI text-embedding-3-small. Returns a 1536-dim float array.
 * Throws on non-2xx. Caller is expected to swallow errors and proceed
 * without retrieval (we never block the user's answer on this).
 */
export async function embedText(opts: EmbedTextOpts): Promise<number[]> {
  const fetcher = opts.fetcher ?? fetch;
  const res = await fetcher(OPENAI_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${opts.openaiApiKey}`,
    },
    // Pseudonymize the user's question before it reaches OpenAI — this path
    // embeds case-fact text and must not leak real names/IDs. Structured PII
    // becomes PERSON_N / EMAIL_N tokens; semantic match is robust to it.
    // See _shared/llm_egress (Data Fortress, 2026-06-13).
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: pseudonymize(opts.text.slice(0, 8000)).text,
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI ${res.status}: ${err.slice(0, 200)}`);
  }
  const json = (await res.json()) as {
    data?: Array<{ embedding?: number[] }>;
  };
  const vec = json.data?.[0]?.embedding;
  if (!Array.isArray(vec) || vec.length !== 1536) {
    throw new Error(`OpenAI returned invalid embedding (len=${vec?.length})`);
  }
  return vec;
}

// ─── 2. Default retriever (calls match_corrections RPC) ────────────────────

function buildDefaultRetriever(
  supabaseUrl: string,
  serviceRoleKey: string
): SimilarityRetriever {
  return async (req) => {
    const res = await fetch(`${supabaseUrl}/rest/v1/rpc/match_corrections`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        p_query_embedding: `[${req.questionEmbedding.join(",")}]`,
        p_jurisdiction: req.jurisdiction ?? null,
        p_threshold: req.threshold,
        p_limit: req.topK,
      }),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`match_corrections ${res.status}: ${err.slice(0, 200)}`);
    }
    const rows = (await res.json()) as CorrectionRow[];
    return Array.isArray(rows) ? rows : [];
  };
}

// ─── 3. Retrieve API ────────────────────────────────────────────────────────

/**
 * Retrieve up to topK corrections semantically similar to [question].
 * Returns an empty array on any failure (network, missing OpenAI key, etc.)
 * — the caller should ALWAYS proceed without retrieval as a safe default.
 */
export async function retrieveCorrections(
  opts: RetrieveCorrectionsOpts
): Promise<CorrectionRow[]> {
  const threshold = opts.threshold ?? DEFAULT_SIMILARITY_THRESHOLD;
  const topK = opts.topK ?? DEFAULT_TOP_K;

  // Test path — inject a retriever, skip OpenAI + Supabase entirely.
  if (opts.retriever) {
    try {
      return await opts.retriever({
        questionEmbedding: new Array(1536).fill(0),
        jurisdiction: opts.jurisdiction,
        threshold,
        topK,
      });
    } catch (e) {
      console.warn(
        `retrieveCorrections (injected): ${String(e).slice(0, 200)}`
      );
      return [];
    }
  }

  // Prod path — embed + RPC.
  if (!opts.openaiApiKey) {
    // No embeddings = no retrieval. Fail open.
    return [];
  }
  let embedding: number[];
  try {
    embedding = await embedText({
      text: opts.question,
      openaiApiKey: opts.openaiApiKey,
    });
  } catch (e) {
    console.warn(`retrieveCorrections embed: ${String(e).slice(0, 200)}`);
    return [];
  }
  const retriever = buildDefaultRetriever(
    opts.supabaseUrl,
    opts.serviceRoleKey
  );
  try {
    return await retriever({
      questionEmbedding: embedding,
      jurisdiction: opts.jurisdiction,
      threshold,
      topK,
    });
  } catch (e) {
    console.warn(`retrieveCorrections RPC: ${String(e).slice(0, 200)}`);
    return [];
  }
}

// ─── 4. Injection block formatter ──────────────────────────────────────────

/**
 * Render retrieved corrections as a `<learned_corrections>` system-prompt
 * block. Caps the total byte size at [CORRECTIONS_BLOCK_MAX_BYTES] (default
 * 4 KB) by truncating later rows or dropping them entirely. The cap is
 * enforced byte-wise on the rendered output, not row-wise — a single very
 * long correction will not blow the budget.
 *
 * Returns "" when [rows] is empty so callers can unconditionally string-
 * concat without a null check.
 */
export function formatCorrectionsBlock(
  rows: CorrectionRow[],
  maxBytes: number = CORRECTIONS_BLOCK_MAX_BYTES
): string {
  if (!rows || rows.length === 0) return "";
  const header = "<learned_corrections>";
  const intro = "Past mistakes you should NOT repeat:";
  const footer = "</learned_corrections>";
  const enc = new TextEncoder();

  // Bytes spent on the framing.
  const framingBytes = enc.encode(`${header}\n${intro}\n\n${footer}`).length;
  let budget = maxBytes - framingBytes;
  if (budget <= 0) return "";

  const renderedRows: string[] = [];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const block = renderRow(i + 1, r);
    const blockBytes = enc.encode(block + "\n").length;
    if (blockBytes <= budget) {
      renderedRows.push(block);
      budget -= blockBytes;
      continue;
    }
    // Try truncating the current block to fit remaining budget.
    if (budget > 200) {
      const truncated = truncateToBytes(block, budget - 4) + " ...";
      renderedRows.push(truncated);
    }
    break; // no more room — stop adding rows
  }
  if (renderedRows.length === 0) return "";

  return [header, intro, "", ...renderedRows, footer].join("\n");
}

function renderRow(idx: number, r: CorrectionRow): string {
  const lines: string[] = [];
  // Compact 4-line form keeps each correction under ~ 400-800 bytes typical.
  const q = (r.question ?? "").trim().replace(/\s+/g, " ").slice(0, 280);
  const w = (r.wrong_advice ?? "").trim().replace(/\s+/g, " ").slice(0, 280);
  const c = (r.correct_answer ?? "").trim().replace(/\s+/g, " ").slice(0, 360);
  const why = (r.why_wrong ?? "").trim().replace(/\s+/g, " ").slice(0, 240);
  lines.push(`${idx}. Q: "${q}"`);
  lines.push(`   WRONG: "${w}"`);
  lines.push(`   CORRECT: "${c}"`);
  if (why) lines.push(`   Why wrong: ${why}`);
  return lines.join("\n");
}

function truncateToBytes(s: string, maxBytes: number): string {
  const enc = new TextEncoder();
  if (enc.encode(s).length <= maxBytes) return s;
  // Binary-shrink — fast enough for our sizes.
  let lo = 0,
    hi = s.length;
  while (lo < hi) {
    const mid = (lo + hi + 1) >>> 1;
    if (enc.encode(s.slice(0, mid)).length <= maxBytes) lo = mid;
    else hi = mid - 1;
  }
  return s.slice(0, lo);
}

// ─── 5. Self-correction reflex ─────────────────────────────────────────────

export interface SelfCorrectionMatch {
  correction_id: string;
  matched_phrase: string;
  wrong_advice: string;
  correct_answer: string;
}

/**
 * Scan a draft reply for any phrase that recreates a known wrong_advice
 * pattern from [rows]. Returns the matches so the caller can decide whether
 * to retry with a "DO NOT REPEAT THIS MISTAKE" prompt addendum.
 *
 * Matching strategy:
 *   * Normalize whitespace + lowercase on both sides.
 *   * For each row, extract the shortest distinctive substring of
 *     wrong_advice (length 12-80) and check substring containment.
 *   * Limit to one match per correction row.
 *   * If wrong_advice is too short for a meaningful substring, fall back
 *     to whole-string equality.
 */
export function selfCorrectionScan(
  draftReply: string,
  rows: CorrectionRow[]
): SelfCorrectionMatch[] {
  if (!draftReply || !rows || rows.length === 0) return [];
  const haystack = normalize(draftReply);
  const out: SelfCorrectionMatch[] = [];
  for (const r of rows) {
    const wrong = normalize(r.wrong_advice ?? "");
    if (!wrong || wrong.length < 8) continue;
    // Use a distinctive sub-phrase to avoid huge-match false-negatives.
    const probe = pickProbe(wrong);
    if (!probe) continue;
    if (haystack.includes(probe)) {
      out.push({
        correction_id: r.id,
        matched_phrase: probe,
        wrong_advice: r.wrong_advice,
        correct_answer: r.correct_answer,
      });
    }
  }
  return out;
}

function normalize(s: string): string {
  return s.toLowerCase().replace(/\s+/g, " ").trim();
}

function pickProbe(wrong: string): string | null {
  // Probe = first 60 chars of the normalized wrong_advice, but trimmed at
  // a word boundary. Very short wrongs use whole-string equality.
  if (wrong.length <= 60) return wrong;
  const head = wrong.slice(0, 60);
  const lastSpace = head.lastIndexOf(" ");
  if (lastSpace >= 30) return head.slice(0, lastSpace);
  return head;
}

/**
 * Build a "DO NOT REPEAT" prompt addendum for the regen pass. Keep it
 * under 1 KB so the second-pass system prompt doesn't balloon.
 */
export function buildSelfCorrectionAddendum(
  matches: SelfCorrectionMatch[]
): string {
  if (matches.length === 0) return "";
  const lines: string[] = ["<do_not_repeat>"];
  lines.push(
    "Your previous draft contained phrasing that matches a KNOWN past mistake."
  );
  lines.push("Re-draft the answer WITHOUT repeating these claims:");
  for (let i = 0; i < matches.length && i < 3; i++) {
    const m = matches[i];
    lines.push(`  - WRONG: "${m.wrong_advice.slice(0, 200)}"`);
    lines.push(`    CORRECT: "${m.correct_answer.slice(0, 280)}"`);
  }
  lines.push("</do_not_repeat>");
  return lines.join("\n");
}
