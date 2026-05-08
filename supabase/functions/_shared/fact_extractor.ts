// fact_extractor.ts — Case Fact Model, Upgrade 2.
// -----------------------------------------------------------------------------
// Extracts structured facts from a chat turn and merges them into the
// user_cases row via the patch_case_facts RPC.
//
// Design:
//   - fire-and-forget: the caller does `.catch()` on the returned Promise.
//   - never throws: all errors are logged and swallowed.
//   - local callAnthropicBlocking copied from consilium.ts to avoid circular
//     imports between _shared modules.
// -----------------------------------------------------------------------------

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL_SONNET = "claude-sonnet-4-6";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface ExtractFactsOpts {
  caseId: string;
  userId: string;
  conversationText: string;
  userMessage: string;
  supabaseUrl: string;
  serviceRoleKey: string;
  anthropicApiKey: string;
}

interface FactItem {
  confidence: "CERTAIN" | "INFERRED";
  [key: string]: unknown;
}

interface ExtractedFacts {
  new_dates?: Array<FactItem & { date?: string; event?: string }>;
  new_case_numbers?: Array<FactItem & { number?: string }>;
  new_parties?: Array<FactItem & { name?: string; role?: string }>;
  contradictions?: Array<FactItem & { description?: string }>;
  new_legal_claims?: Array<FactItem & { claim?: string }>;
  open_questions?: Array<FactItem & { question?: string }>;
}

// ─── System prompt ───────────────────────────────────────────────────────────

const EXTRACTOR_SYSTEM = `You are a structured legal fact extractor. Extract new facts from the conversation snippet.

Output ONLY valid JSON in this exact shape — no markdown, no explanation:
{
  "new_dates": [{"date": "YYYY-MM-DD or natural date", "event": "description", "confidence": "CERTAIN"|"INFERRED"}],
  "new_case_numbers": [{"number": "string", "confidence": "CERTAIN"|"INFERRED"}],
  "new_parties": [{"name": "string", "role": "string", "confidence": "CERTAIN"|"INFERRED"}],
  "contradictions": [{"description": "string", "confidence": "CERTAIN"|"INFERRED"}],
  "new_legal_claims": [{"claim": "string", "confidence": "CERTAIN"|"INFERRED"}],
  "open_questions": [{"question": "string", "confidence": "CERTAIN"|"INFERRED"}]
}

Rules:
- CERTAIN: explicitly stated in text with no ambiguity.
- INFERRED: implied or uncertain — requires verification.
- Omit arrays that have zero items.
- Extract only NEW facts not already obvious from the question.
- If nothing meaningful to extract, return {}.`;

// ─── Local callAnthropicBlocking (copied from consilium.ts, no import) ───────

function buildAnthropicHeaders(apiKey: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": "2023-06-01",
  };
}

async function callAnthropicBlocking(opts: {
  model: string;
  system: string;
  userMessage: string;
  maxTokens: number;
  temperature: number;
  apiKey: string;
}): Promise<string> {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: buildAnthropicHeaders(opts.apiKey),
    body: JSON.stringify({
      model: opts.model,
      max_tokens: opts.maxTokens,
      temperature: opts.temperature,
      system: opts.system,
      messages: [{ role: "user", content: opts.userMessage }],
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(
      `Anthropic ${res.status} (${opts.model}): ${errText.slice(0, 200)}`,
    );
  }

  const json = await res.json() as {
    content?: Array<{ type: string; text?: string }>;
  };

  return (json.content ?? [])
    .filter((b) => b.type === "text" && typeof b.text === "string")
    .map((b) => b.text!)
    .join("");
}

// ─── Main export ─────────────────────────────────────────────────────────────

/**
 * Fire-and-forget: extract structured facts from a chat turn and persist them
 * via the patch_case_facts RPC. Never throws — all errors are logged and
 * swallowed. The caller should do `.catch((e) => console.warn(...))` on the
 * returned Promise.
 */
export async function extractAndPatchFacts(
  opts: ExtractFactsOpts,
): Promise<void> {
  // ── Step 1: call Anthropic to extract facts ───────────────────────────────
  let rawJson: string;
  try {
    const userTurn =
      `<user_turn>${opts.userMessage.slice(0, 1000)}</user_turn>\n` +
      `<assistant_reply>${opts.conversationText.slice(0, 6000)}</assistant_reply>`;

    rawJson = await callAnthropicBlocking({
      model: MODEL_SONNET,
      system: EXTRACTOR_SYSTEM,
      userMessage: userTurn,
      maxTokens: 600,
      temperature: 0.0,
      apiKey: opts.anthropicApiKey,
    });
  } catch (e) {
    console.warn(
      `fact_extractor: Anthropic call failed for case ${opts.caseId}: ${
        String(e).slice(0, 200)
      }`,
    );
    return;
  }

  // ── Step 2: parse JSON ────────────────────────────────────────────────────
  let facts: ExtractedFacts;
  try {
    // Strip markdown code fences if the model slipped them in.
    const cleaned = rawJson.trim().replace(/^```json?\s*/i, "").replace(
      /```\s*$/,
      "",
    );
    facts = JSON.parse(cleaned) as ExtractedFacts;
  } catch (e) {
    console.warn(
      `fact_extractor: JSON parse failed for case ${opts.caseId}: ${
        String(e).slice(0, 100)
      } | raw: ${rawJson.slice(0, 200)}`,
    );
    return;
  }

  // ── Step 3: build RPC arguments ──────────────────────────────────────────
  const certainDates = (facts.new_dates ?? [])
    .filter((d) => d.confidence === "CERTAIN")
    .map((d) => ({ date: d.date ?? "", event: d.event ?? "" }));

  const certainParties = (facts.new_parties ?? [])
    .filter((p) => p.confidence === "CERTAIN")
    .map((p) => ({ name: p.name ?? "", role: p.role ?? "" }));

  const certainCaseNumbers = (facts.new_case_numbers ?? [])
    .filter((c) => c.confidence === "CERTAIN")
    .map((c) => c.number ?? "")
    .filter(Boolean);

  // open_questions: all INFERRED items from all arrays + explicit open_questions
  const openQuestions: string[] = [];

  for (const d of (facts.new_dates ?? []).filter(
    (d) => d.confidence === "INFERRED",
  )) {
    openQuestions.push(`Date? ${d.date ?? ""}: ${d.event ?? ""}`);
  }
  for (const c of (facts.new_case_numbers ?? []).filter(
    (c) => c.confidence === "INFERRED",
  )) {
    openQuestions.push(`Case number? ${c.number ?? ""}`);
  }
  for (const p of (facts.new_parties ?? []).filter(
    (p) => p.confidence === "INFERRED",
  )) {
    openQuestions.push(`Party? ${p.name ?? ""} (${p.role ?? ""})`);
  }
  for (const lc of (facts.new_legal_claims ?? []).filter(
    (lc) => lc.confidence === "INFERRED",
  )) {
    openQuestions.push(`Claim? ${lc.claim ?? ""}`);
  }
  for (const oq of (facts.open_questions ?? [])) {
    openQuestions.push(oq.question ?? String(oq));
  }

  const contradictions = (facts.contradictions ?? []).map(
    (c) => c.description ?? String(c),
  );

  const legalClaims = (facts.new_legal_claims ?? [])
    .filter((lc) => lc.confidence === "CERTAIN")
    .map((lc) => lc.claim ?? "")
    .filter(Boolean);

  // ── Step 4: call Supabase RPC ─────────────────────────────────────────────
  try {
    const rpcRes = await fetch(
      `${opts.supabaseUrl}/rest/v1/rpc/patch_case_facts`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": opts.serviceRoleKey,
          "Authorization": `Bearer ${opts.serviceRoleKey}`,
        },
        body: JSON.stringify({
          p_case_id: opts.caseId,
          p_certain_dates: certainDates,
          p_certain_parties: certainParties,
          p_certain_case_numbers: certainCaseNumbers,
          p_open_questions: openQuestions,
          p_contradictions: contradictions,
          p_legal_claims: legalClaims,
        }),
      },
    );

    if (!rpcRes.ok) {
      const errText = await rpcRes.text();
      console.warn(
        `fact_extractor: patch_case_facts RPC failed ${rpcRes.status} for case ${opts.caseId}: ${
          errText.slice(0, 200)
        }`,
      );
    }
  } catch (e) {
    console.warn(
      `fact_extractor: patch_case_facts fetch threw for case ${opts.caseId}: ${
        String(e).slice(0, 200)
      }`,
    );
  }
}
