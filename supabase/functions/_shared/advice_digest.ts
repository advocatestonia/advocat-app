// advice_digest.ts — stores and retrieves compact legal conclusions per case.
// Fire-and-forget write after each planner/consilium response.
// Injected as <prior_advice> block in subsequent sessions.

import { recordSpend } from "./spend_tracker.ts";
import { scrubAnthropicBody } from "./llm_egress/scrub_body.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL_HAIKU = "claude-haiku-4-5-20251001"; // Haiku OK here — just summarizing

export interface AdviceDigestEntry {
  session_date: string; // ISO date
  conclusion: string; // 1-2 sentence summary of key legal conclusion
  probability_signal?: string;
  track?: string; // e.g. "KHO valituslupa", "Valtiokonttori", etc.
}

export async function appendAdviceDigest(opts: {
  caseId: string;
  replyText: string;
  probabilitySignal: string;
  supabaseUrl: string;
  serviceRoleKey: string;
  anthropicApiKey: string;
}): Promise<void> {
  // 1. Use Haiku to extract 1-2 sentence legal conclusion from replyText
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": opts.anthropicApiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(
      scrubAnthropicBody({
        model: MODEL_HAIKU,
        max_tokens: 150,
        temperature: 0.0,
        system:
          "Extract the single most important legal conclusion from this AI legal advice. " +
          "Output ONLY a 1-2 sentence summary. No preamble. Focus on: what is recommended, " +
          "what probability was stated, what the next step is. If no clear legal conclusion, output: SKIP",
        messages: [{ role: "user", content: opts.replyText.slice(0, 3000) }],
      })
    ),
  });
  if (!res.ok) return;
  const json = (await res.json()) as {
    content?: Array<{ text?: string }>;
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
  // Cost-audit gap 2026-05-27: record Haiku spend so the digest summarizer
  // contributes to anthropic_daily_spend. Best-effort.
  try {
    const u = json.usage ?? {};
    const inputTokens =
      (u.input_tokens ?? 0) +
      (u.cache_creation_input_tokens ?? 0) +
      (u.cache_read_input_tokens ?? 0);
    const outputTokens = u.output_tokens ?? 0;
    if (inputTokens > 0 || outputTokens > 0) {
      recordSpend(
        inputTokens,
        outputTokens,
        MODEL_HAIKU,
        "anthropic_haiku"
      ).catch(() => {});
    }
  } catch (_e) {
    /* never bubble */
  }
  const conclusion = json.content?.[0]?.text?.trim() ?? "";
  if (!conclusion || conclusion === "SKIP") return;

  // 2. Append to user_cases.advice_digest jsonb array (append-only, never overwrite)
  const entry: AdviceDigestEntry = {
    session_date: new Date().toISOString().slice(0, 10),
    conclusion,
    probability_signal: opts.probabilitySignal || undefined,
  };

  await fetch(`${opts.supabaseUrl}/rest/v1/rpc/append_advice_digest`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: opts.serviceRoleKey,
      Authorization: `Bearer ${opts.serviceRoleKey}`,
    },
    body: JSON.stringify({ p_case_id: opts.caseId, p_entry: entry }),
  });
}

export function formatAdviceDigestBlock(entries: AdviceDigestEntry[]): string {
  if (!entries || entries.length === 0) return "";
  // Keep only last 5 entries to stay within token budget
  const recent = entries.slice(-5);
  const lines = [
    "<prior_advice>",
    "Previous conclusions from earlier sessions:",
  ];
  for (const e of recent) {
    lines.push(
      `  [${e.session_date}] ${e.conclusion}${
        e.probability_signal ? ` (${e.probability_signal})` : ""
      }`
    );
  }
  lines.push(
    "If your current answer contradicts a prior conclusion, explicitly acknowledge the change and explain why."
  );
  lines.push("</prior_advice>");
  return lines.join("\n");
}
