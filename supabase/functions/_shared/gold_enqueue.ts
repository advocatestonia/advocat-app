// gold_enqueue.ts — fire-and-forget queue insert after a Claude answer.
// ----------------------------------------------------------------------------
// Called from claude-proxy AFTER the final reply has been sent. Must NEVER
// block the response and MUST NEVER throw — every failure mode swallows
// silently. The training corpus can wait; the user reply cannot.
//
// Sampling: configurable via env (GOLD_CORPUS_SAMPLE_RATE, default 0.5).
// Anon callers and short messages (<50 chars) are skipped.
// ----------------------------------------------------------------------------

export interface EnqueueGoldParams {
  userId: string | null;          // null for anon
  sourceMessageId?: string | null;
  userQuestion: string;
  aiAnswer: string;
  aiModel?: string | null;
  aiCitations?: string[];
  language?: string | null;
  category?: string | null;
  jurisdiction?: string | null;
  supabaseUrl: string;
  serviceRoleKey: string;
  /** Override the env sample rate (for tests / future per-cohort tuning). */
  sampleRate?: number;
  /** Deterministic sampler (for tests). Default Math.random. */
  rng?: () => number;
  /** Fetch override (for tests). */
  fetcher?: typeof fetch;
}

const MIN_QUESTION_LEN = 50;

/** Default sampling rate read from env once at module load. */
const DEFAULT_SAMPLE_RATE = (() => {
  const raw = Deno.env.get("GOLD_CORPUS_SAMPLE_RATE");
  if (!raw) return 0.5;
  const v = parseFloat(raw);
  if (!Number.isFinite(v) || v < 0 || v > 1) return 0.5;
  return v;
})();

/**
 * Decide whether a (userId, question) pair should be enqueued.
 * Pure function for testability: no I/O, no env reads.
 */
export function shouldEnqueueGold(opts: {
  userId: string | null;
  userQuestion: string;
  sampleRate: number;
  rng: () => number;
}): boolean {
  if (!opts.userId) return false;                          // anon — skip
  if (opts.userId.startsWith("anon:")) return false;       // synthetic anon
  if (!opts.userQuestion) return false;
  if (opts.userQuestion.trim().length < MIN_QUESTION_LEN) return false;
  if (opts.sampleRate <= 0) return false;
  if (opts.sampleRate >= 1) return true;
  return opts.rng() < opts.sampleRate;
}

/**
 * Fire-and-forget enqueue. Always resolves; never throws.
 */
export async function enqueueGoldCandidate(p: EnqueueGoldParams): Promise<void> {
  const sampleRate = p.sampleRate ?? DEFAULT_SAMPLE_RATE;
  const rng = p.rng ?? Math.random;

  const decision = shouldEnqueueGold({
    userId: p.userId,
    userQuestion: p.userQuestion,
    sampleRate,
    rng,
  });
  if (!decision) return;

  // Defensive: a hard cap on what we send to PG (TOAST handles huge text but
  // we don't want a single 1MB reply to blow up the queue row).
  const userQuestion = p.userQuestion.slice(0, 20_000);
  const aiAnswer = p.aiAnswer.slice(0, 60_000);

  const fetcher = p.fetcher ?? fetch;
  try {
    const res = await fetcher(`${p.supabaseUrl}/rest/v1/gold_corpus_queue`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: p.serviceRoleKey,
        Authorization: `Bearer ${p.serviceRoleKey}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        source_user_id: p.userId,
        source_message_id: p.sourceMessageId ?? null,
        user_question: userQuestion,
        ai_answer: aiAnswer,
        ai_model: p.aiModel ?? null,
        ai_citations: p.aiCitations ?? null,
        language: p.language ?? null,
        category: p.category ?? null,
        jurisdiction: p.jurisdiction ?? "estonia",
      }),
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => "");
      console.warn(
        `[gold-enqueue] insert HTTP ${res.status}: ${txt.slice(0, 200)}`,
      );
    }
  } catch (err) {
    console.warn(`[gold-enqueue] insert threw: ${String(err).slice(0, 200)}`);
  }
}
