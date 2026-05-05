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
  "deport", "appeal", "court", "lawsuit", "lawyer", "tenant", "landlord",
  "evict", "fired", "dismissal", "custody", "divorce", "subpoena", "fine",
  "complaint", "claim", "rights", "violation", "warrant", "asylum",
  // Russian
  "жалоб", "депорт", "суд", "адвокат", "развод", "увольнен", "выселен",
  "штраф", "иск", "квартир", "договор", "наруш", "права", "выдвор",
  "апелляц", "обжалов",
  // Estonian
  "deportats", "kohus", "kohtu", "koht", "advokaat", "kaebus", "üür",
  "töölt", "vallandam", "lahutus", "trahv", "rikkum", "õigus",
  "väljasaatm", "apellats",
  // Finnish
  "karkot", "tuomioistuin", "asianajaja", "valitus", "vuokra", "irtisano",
  "avioero", "sakko", "rikkomus", "oikeu",
  // German
  "abschieb", "gericht", "anwalt", "berufung", "miete", "kündig",
  "scheidung", "bußgeld", "verstoß", "recht",
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
