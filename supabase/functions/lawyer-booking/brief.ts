// lawyer-booking/brief.ts
// -----------------------------------------------------------------------------
// AI brief generator. Called by the edge fn 2h before the scheduled slot
// (or, for "schedule-immediate" bookings, right after status flips to
// 'confirmed'). The output is markdown the lawyer reads on their dashboard
// before the call.
//
// The brief is intentionally short — a 15-minute call has no room for an
// essay. Target: ≤ 1500 tokens of output.
//
// Routing: we call claude-proxy (NOT Anthropic direct) so we inherit the
// $-balance fallback and the per-user quota guardrails. Output schema is
// strict markdown; we don't try to JSON-parse anything.
//
// Failure mode: if claude-proxy is unreachable or returns garbage, we
// store a "skeleton" brief built from the raw inputs so the lawyer is
// never staring at an empty dashboard.
// -----------------------------------------------------------------------------

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

/** Inputs gathered from the booking + (optional) attached case. */
export interface BriefInputs {
  topic: string;
  language: string;
  userBrief: string | null;
  userDisplayName: string;
  /** Optional case_facts JSON snapshot (when case_id was attached). */
  caseFactsJson: Record<string, unknown> | null;
  /** Recent significant messages from the case chat, capped to ~3KB. */
  caseChatExcerpt: string | null;
}

export interface BriefResult {
  /** Always non-null — falls back to a hand-crafted skeleton on AI error. */
  markdown: string;
  /** "ai" or "skeleton" — telemetry only. */
  source: "ai" | "skeleton";
}

/**
 * Build the brief. Never throws — on any failure returns the skeleton
 * variant. Edge fn callers should always store `result.markdown`.
 */
export async function generateBrief(
  inputs: BriefInputs,
  userJwt: string,
): Promise<BriefResult> {
  const skeleton = buildSkeleton(inputs);

  // If we don't have a Supabase URL configured (test env), return skeleton.
  if (!SUPABASE_URL || !userJwt) {
    return { markdown: skeleton, source: "skeleton" };
  }

  const system = buildSystemPrompt(inputs);
  const user = buildUserPrompt(inputs);

  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/claude-proxy`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${userJwt}`,
        // Use the service-role apikey header so claude-proxy's edge-fn-
        // origin check passes. The user JWT in Authorization is what's
        // used for quota — same pattern as send-email/contract-review.
        "apikey": SERVICE_KEY,
      },
      body: JSON.stringify({
        // Match the schema claude-proxy already accepts.
        messages: [{ role: "user", content: user }],
        system,
        max_tokens: 1500,
        // We don't need any tools or memory injection for this short call.
        skip_memory: true,
        skip_tools: true,
        // Tag for spend-tracking dashboards.
        meta: { feature: "lawyer-booking", subfeature: "brief" },
      }),
      // 30s budget — claude-proxy normally returns in 2-5s.
      signal: AbortSignal.timeout(30_000),
    });

    if (!res.ok) {
      console.warn("[lawyer-booking/brief] claude-proxy non-2xx:", res.status);
      return { markdown: skeleton, source: "skeleton" };
    }
    const payload = await res.json();
    // claude-proxy returns either {text} or {content:[{text}]}, mirror
    // both shapes.
    let ai: string | null = null;
    if (typeof payload?.text === "string") ai = payload.text;
    if (!ai && Array.isArray(payload?.content)) {
      const t = payload.content[0]?.text;
      if (typeof t === "string") ai = t;
    }
    if (!ai || ai.trim().length < 50) {
      return { markdown: skeleton, source: "skeleton" };
    }
    // Hard cap — DB column allows 20K but we keep AI output ≤ 8K so the
    // lawyer can scan it in under a minute.
    const clipped = ai.length > 8000 ? ai.slice(0, 8000) + "\n\n…(truncated)" : ai;
    return { markdown: clipped, source: "ai" };
  } catch (e) {
    console.warn("[lawyer-booking/brief] generate failed:", e);
    return { markdown: skeleton, source: "skeleton" };
  }
}

// ─── Prompt builders ────────────────────────────────────────────────────────

function buildSystemPrompt(inputs: BriefInputs): string {
  const lang = languageName(inputs.language);
  return `You are preparing a pre-call brief for a licensed attorney who is about \
to take a 15-minute paid call with a user of Advocat (an AI legal-info \
service). The user is NOT yet your client — this is an introductory \
consultation. Write in ${lang}.

Hard rules:
- Maximum 600 words. The lawyer has 90 seconds to read this before the call.
- Markdown, with these EXACT four H2 sections in order:
  ## Situation
  ## Key facts
  ## Likely legal questions
  ## What the user has already tried
- Each section: 3-6 bullet points OR short paragraph. No fluff.
- If a piece of information is missing, write "(not stated)" — never invent.
- Never cite specific statutes unless they appear verbatim in the inputs.
- End with a single line: "Suggested opener: …" with a one-sentence \
warm opening question the lawyer can ask.`;
}

function buildUserPrompt(inputs: BriefInputs): string {
  const parts: string[] = [];
  parts.push(`Topic the user picked: **${inputs.topic}**`);
  parts.push(`User display name: ${inputs.userDisplayName}`);
  parts.push(`Call language requested: ${inputs.language}`);
  parts.push("");
  if (inputs.userBrief) {
    parts.push("### What the user wrote in the booking form");
    parts.push(inputs.userBrief);
    parts.push("");
  }
  if (inputs.caseFactsJson) {
    parts.push("### Structured case facts on file");
    parts.push("```json");
    parts.push(JSON.stringify(inputs.caseFactsJson, null, 2).slice(0, 4000));
    parts.push("```");
    parts.push("");
  }
  if (inputs.caseChatExcerpt) {
    parts.push("### Recent chat excerpt (most relevant messages)");
    parts.push(inputs.caseChatExcerpt.slice(0, 3000));
    parts.push("");
  }
  if (parts.length === 4) {
    // Only header lines were added — no actual content beyond the topic.
    parts.push("(The user has not provided additional context yet.)");
  }
  return parts.join("\n");
}

// ─── Skeleton fallback ──────────────────────────────────────────────────────

/**
 * Hand-built markdown used when the AI is unreachable. Strictly mechanical
 * concatenation of the inputs — guarantees the lawyer always has SOMETHING.
 * Format-matches the AI prompt so the dashboard renderer stays simple.
 */
function buildSkeleton(inputs: BriefInputs): string {
  const lines: string[] = [];
  lines.push("## Situation");
  lines.push(
    `- Topic the user picked: **${inputs.topic}**`,
  );
  lines.push(`- Preferred language for the call: ${inputs.language}`);
  lines.push(`- Booked under user: ${inputs.userDisplayName}`);
  lines.push("");
  lines.push("## Key facts");
  if (inputs.caseFactsJson) {
    const keys = Object.keys(inputs.caseFactsJson).slice(0, 8);
    if (keys.length === 0) {
      lines.push("- (no structured facts available)");
    } else {
      for (const k of keys) {
        const v = JSON.stringify(inputs.caseFactsJson[k]).slice(0, 200);
        lines.push(`- ${k}: ${v}`);
      }
    }
  } else {
    lines.push("- (no case attached)");
  }
  lines.push("");
  lines.push("## Likely legal questions");
  lines.push("- (auto-brief unavailable — please draw these out on the call)");
  lines.push("");
  lines.push("## What the user has already tried");
  if (inputs.userBrief && inputs.userBrief.length > 0) {
    // Indent the user-written brief as a quote block.
    for (const line of inputs.userBrief.split(/\r?\n/)) {
      lines.push(`> ${line}`);
    }
  } else {
    lines.push("- (the user did not add a free-text brief)");
  }
  lines.push("");
  lines.push(
    "Suggested opener: Could you walk me through what happened, in your own words?",
  );
  return lines.join("\n");
}

function languageName(code: string): string {
  switch (code) {
    case "et":
      return "Estonian";
    case "fi":
      return "Finnish";
    case "ru":
      return "Russian";
    case "en":
      return "English";
    case "de":
      return "German";
    case "sv":
      return "Swedish";
    case "fr":
      return "French";
    default:
      return code;
  }
}

// ─── Test surface ───────────────────────────────────────────────────────────
export const __testing = { buildSkeleton, buildSystemPrompt, buildUserPrompt };
