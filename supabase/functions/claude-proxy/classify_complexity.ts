// =============================================================================
// classify_complexity.ts — heuristic-driven extended-thinking budgeter.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). The chat client always-on-streams; this
// module decides how much "thinking" budget Anthropic gets for each turn.
//
// Why: extended thinking is expensive and slow. We DO want it for genuine
// legal questions ("Got a deportation notice — what's my appeal window?")
// but NOT for greetings or yes/no follow-ups. Anon users get NO thinking at
// all because their max_tokens is clamped to 500 — turning on thinking with
// budget > max_tokens errors out the API.
//
// Output: an object suitable for forwarding straight into Anthropic's
// `body.thinking` field, OR null when the turn should not use thinking.
//
//   { type: "enabled", budget_tokens: 6144, display: "summarized" }   -- complex
//   { type: "enabled", budget_tokens: 2048, display: "summarized" }   -- medium
//   null                                                              -- skip
//
// `display: "summarized"` is critical: it tells Anthropic to return a short,
// sanitised summary of each thinking block, NOT the verbatim chain-of-thought
// (which is high-risk to render and longer than the pill caption can hold).
// =============================================================================

interface Message {
  role?: string;
  content?: unknown;
}

export interface ThinkingConfig {
  type: "enabled";
  budget_tokens: number;
  display: "summarized";
}

/** Legal-keyword regex (case-insensitive, multilingual). Hits in EN, RU, ET,
 *  FI, DE — the priority five. Match short stems on word boundaries to keep
 *  the test stable as we add more languages. */
const LEGAL_KEYWORDS = [
  // English
  "deport",
  "appeal",
  "court",
  "lawsuit",
  "lawyer",
  "tenant",
  "landlord",
  "evict",
  "fired",
  "dismissal",
  "custody",
  "divorce",
  "subpoena",
  "fine",
  "complaint",
  "claim",
  "rights",
  "violation",
  "warrant",
  "asylum",
  // Russian
  "жалоб",
  "депорт",
  "суд",
  "адвокат",
  "развод",
  "увольнен",
  "выселен",
  "штраф",
  "иск",
  "квартир",
  "договор",
  "наруш",
  "права",
  "выдвор",
  "апелляц",
  "обжалов",
  // Estonian
  "deportats",
  "kohus",
  "kohtu",
  "koht",
  "advokaat",
  "kaebus",
  "üür",
  "töölt",
  "vallandam",
  "lahutus",
  "trahv",
  "rikkum",
  "õigus",
  "väljasaatm",
  "apellats",
  // Finnish
  "karkot",
  "tuomioistuin",
  "asianajaja",
  "valitus",
  "vuokra",
  "irtisano",
  "avioero",
  "sakko",
  "rikkomus",
  "oikeu",
  // German
  "abschieb",
  "gericht",
  "anwalt",
  "berufung",
  "miete",
  "kündig",
  "scheidung",
  "bußgeld",
  "verstoß",
  "recht",
];

const LEGAL_KEYWORDS_REGEX = new RegExp(
  LEGAL_KEYWORDS.map((s) => s.toLowerCase()).join("|"),
  "i",
);

/** Threshold (chars) above which we assume the user is genuinely asking
 *  rather than greeting / asking a meta-question. */
const COMPLEX_LENGTH_THRESHOLD = 180;

/** Budget for "complex" turns — enough for a multi-step legal reasoning
 *  pass with a tool call or two. */
export const BUDGET_COMPLEX = 6144;

/** Budget for "medium" turns — covers a couple of reasoning steps but
 *  doesn't burn budget on greetings. */
export const BUDGET_MEDIUM = 2048;

/**
 * Classify the latest user turn and decide whether to attach thinking.
 *
 *   userIsAnon: anon caller (synthetic anon:<ip> principal). Their
 *     max_tokens is clamped to 500 elsewhere in the proxy — passing
 *     thinking > 500 would error, so we never enable for anon.
 *
 *   hasTools: whether the request body declared tools[]. Tool-eligible
 *     turns always get at least medium budget so the model has room to
 *     decide whether to call a tool.
 */
export function classifyComplexity(
  messages: Message[],
  userIsAnon: boolean,
  options: { hasTools?: boolean } = {},
): ThinkingConfig | null {
  if (userIsAnon) {
    return null;
  }
  if (!Array.isArray(messages) || messages.length === 0) {
    return null;
  }

  const last = messages[messages.length - 1];
  if (last?.role !== "user") {
    // Defensive: if the last message is from the assistant we're in a
    // weird state — don't burn budget.
    return null;
  }

  const text = extractUserText(last.content).toLowerCase().trim();
  if (text.length === 0) {
    return null;
  }

  const looksLegal = LEGAL_KEYWORDS_REGEX.test(text);
  const isLong = text.length >= COMPLEX_LENGTH_THRESHOLD;
  const isShort = text.length < 25 && !looksLegal;

  // Pure-greeting heuristic: very short non-legal message → no thinking.
  // Saves budget on "hi", "ok", "thanks" turns.
  if (isShort) {
    return null;
  }

  if (looksLegal || isLong) {
    return {
      type: "enabled",
      budget_tokens: BUDGET_COMPLEX,
      display: "summarized",
    };
  }

  if (options.hasTools) {
    return {
      type: "enabled",
      budget_tokens: BUDGET_MEDIUM,
      display: "summarized",
    };
  }

  return {
    type: "enabled",
    budget_tokens: BUDGET_MEDIUM,
    display: "summarized",
  };
}

/** Anthropic accepts both `content: "string"` and `content: [{type:'text', text:...}]`.
 *  Normalise to a flat string we can run regex against. */
function extractUserText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    const out: string[] = [];
    for (const block of content) {
      if (
        block && typeof block === "object" &&
        (block as Record<string, unknown>).type === "text" &&
        typeof (block as Record<string, unknown>).text === "string"
      ) {
        out.push((block as Record<string, string>).text);
      }
    }
    return out.join(" ");
  }
  return "";
}

// =============================================================================
// Wave-1 fix (2026-06-11) — per-model thinking compatibility
// =============================================================================
//
// The proxy can route a turn to Opus 4.8 AFTER classifyComplexity attached
// `{type:"enabled", budget_tokens:N}`. Opus 4.7+ removed `budget_tokens`
// entirely — adaptive (`{type:"adaptive"}`) is the only on-mode — and also
// removed the sampling params (temperature / top_p / top_k). Sending either
// shape produced a hard Anthropic 400 on every "complex" turn in production
// (the Flutter client sends temperature on every call, so even a turn
// without thinking would 400 on Opus).
//
// Conversely the budget-style models in the allowlist (Haiku 4.5, Sonnet 4)
// reject `{type:"adaptive"}`. `applyModelThinkingCompat` reconciles
// body.thinking + sampling params with the FINAL body.model and MUST run
// after the signal router picks that model (index.ts).
// =============================================================================

/** Adaptive thinking shape for Opus 4.7+ / Fable-family models.
 *  `display:"summarized"` keeps the sanitised-summary contract the client
 *  pill UI depends on (same rationale as ThinkingConfig above). */
export interface AdaptiveThinkingConfig {
  type: "adaptive";
  display: "summarized" | "omitted";
}

/** Models whose thinking is adaptive-only (`budget_tokens` fully removed):
 *  Opus 4.7 / 4.8 and the Fable/Mythos 5 family. Haiku 4.5 and Sonnet 4
 *  keep the legacy `{type:"enabled", budget_tokens}` shape. */
export function isAdaptiveOnlyThinkingModel(modelId: string): boolean {
  return (
    /^claude-opus-4-[78]/.test(modelId) ||
    /^claude-(fable|mythos)-/.test(modelId)
  );
}

interface ThinkingCompatBody {
  model?: unknown;
  thinking?: unknown;
  max_tokens?: unknown;
  temperature?: unknown;
  top_p?: unknown;
  top_k?: unknown;
}

/** Mutate `body` so its `thinking` + sampling params are valid for the
 *  final `body.model`. Pure shape translation — never throws, never
 *  changes which model is called.
 *
 *  Adaptive-only model (Opus 4.8 …):
 *    - `{type:"enabled", budget_tokens}` → `{type:"adaptive", display}`
 *    - temperature / top_p / top_k are DELETED (removed params → 400)
 *    - adaptive / disabled / absent pass through unchanged
 *
 *  Budget-style model (Haiku 4.5, Sonnet 4):
 *    - `{type:"adaptive"}` → `{type:"enabled", budget_tokens}` clamped
 *      under max_tokens (API requires budget < max_tokens); dropped when
 *      max_tokens leaves no usable budget
 *    - enabled / absent pass through unchanged */
export function applyModelThinkingCompat(body: ThinkingCompatBody): void {
  if (typeof body.model !== "string") return;
  const thinking = body.thinking && typeof body.thinking === "object"
    ? (body.thinking as { type?: unknown; display?: unknown })
    : null;

  if (isAdaptiveOnlyThinkingModel(body.model)) {
    // Sampling params were removed on Opus 4.7+ — they 400 the call.
    delete body.temperature;
    delete body.top_p;
    delete body.top_k;
    if (thinking?.type === "enabled") {
      const compat: AdaptiveThinkingConfig = {
        type: "adaptive",
        display: thinking.display === "omitted" ? "omitted" : "summarized",
      };
      body.thinking = compat;
    }
    return;
  }

  // Budget-style model — "adaptive" is rejected; translate it.
  if (thinking?.type === "adaptive") {
    const maxTokens = typeof body.max_tokens === "number"
      ? body.max_tokens
      : undefined;
    let budget = BUDGET_COMPLEX;
    if (maxTokens !== undefined && budget >= maxTokens) budget = BUDGET_MEDIUM;
    if (maxTokens !== undefined && budget >= maxTokens) {
      // max_tokens too small for any meaningful budget (API min 1024) —
      // a thinking-less turn is better than a guaranteed 400.
      delete body.thinking;
      return;
    }
    const compat: ThinkingConfig = {
      type: "enabled",
      budget_tokens: budget,
      display: "summarized",
    };
    body.thinking = compat;
  }
}
