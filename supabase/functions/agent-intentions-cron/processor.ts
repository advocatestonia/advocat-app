// processor.ts — pure logic for the agent-intentions cron loop.
// -----------------------------------------------------------------------------
// Extracted from index.ts so it can be unit-tested without spinning up
// the Deno HTTP listener or hitting Supabase. The Supabase client is
// injected as a minimal interface the tests can fake.
// -----------------------------------------------------------------------------

export interface IntentionRow {
  id: string;
  user_id: string;
  case_id: string | null;
  intent_type:
    | "remind_deadline"
    | "check_court_status"
    | "follow_up_question"
    | "check_company_status";
  target_id: string | null;
  next_check_at: string;
  conversation_context: { summary?: string; locale?: string } | null;
  completed: boolean;
}

export interface MinimalSupabase {
  fetchDueIntentions(now: Date, limit: number): Promise<IntentionRow[]>;
  fetchUserEmail(userId: string): Promise<string | null>;
  insertNotification(row: {
    user_id: string;
    type: string;
    title: string;
    body: string;
  }): Promise<void>;
  markIntentionComplete(id: string, now: Date): Promise<void>;
}

export interface ProcessResult {
  processed: number;
  errors: number;
}

/**
 * Build the email/notification copy for a single intention. Pure — no IO.
 * Owner spec calls this out as the WOW moment ("Sulga, прошёл месяц…")
 * so the body must reference the saved context_summary, not a generic
 * boilerplate.
 */
export function renderNotification(
  row: IntentionRow,
): { title: string; body: string } {
  const summary = row.conversation_context?.summary?.trim() || "";
  const locale = row.conversation_context?.locale || "en";

  switch (row.intent_type) {
    case "remind_deadline": {
      const titleByLocale: Record<string, string> = {
        ru: "Напоминание: " + (summary || "проверь дедлайн"),
        et: "Meeldetuletus: " + (summary || "kontrolli tähtaega"),
        en: "Reminder: " + (summary || "check this deadline"),
      };
      const bodyByLocale: Record<string, string> = {
        ru:
          summary
            ? `Прошло время — ${summary}. Я могу помочь подготовить документы или проверить статус.`
            : "Я обещал напомнить — проверь свой дедлайн.",
        et:
          summary
            ? `Aeg on käes — ${summary}. Saan aidata dokumente koostada või staatust kontrollida.`
            : "Lubasin meelde tuletada — kontrolli oma tähtaega.",
        en:
          summary
            ? `It's time — ${summary}. I can help draft documents or check the status.`
            : "I promised to remind you — check your deadline.",
      };
      return {
        title: titleByLocale[locale] ?? titleByLocale.en,
        body: bodyByLocale[locale] ?? bodyByLocale.en,
      };
    }

    case "check_court_status": {
      const target = row.target_id || "your case";
      const titleByLocale: Record<string, string> = {
        ru: `Проверка статуса дела ${target}`,
        et: `Kohtuasja ${target} staatuse kontroll`,
        en: `Court status check — ${target}`,
      };
      const bodyByLocale: Record<string, string> = {
        ru:
          `Я обещал проверить дело ${target} (${summary}). ` +
            "Скажи, есть ли новости — я смогу помочь дальше.",
        et:
          `Lubasin kohtuasja ${target} kontrollida (${summary}). ` +
            "Anna teada, kui on uudiseid — saan edasi aidata.",
        en:
          `I was supposed to check on ${target} — ${summary}. ` +
            "Please share the latest update so I can help.",
      };
      return {
        title: titleByLocale[locale] ?? titleByLocale.en,
        body: bodyByLocale[locale] ?? bodyByLocale.en,
      };
    }

    case "follow_up_question": {
      const titleByLocale: Record<string, string> = {
        ru: "Привет — как дела с " + (summary || "твоим делом") + "?",
        et: "Tere — kuidas läheb? " + (summary || ""),
        en: "Checking in — how is " + (summary || "your case") + "?",
      };
      const bodyByLocale: Record<string, string> = {
        ru:
          `В прошлый раз мы говорили про: ${summary}. Как обстановка?`,
        et:
          `Eelmine kord rääkisime: ${summary}. Kuidas läheb?`,
        en: `Last time we talked about: ${summary}. How is it going?`,
      };
      return {
        title: titleByLocale[locale] ?? titleByLocale.en,
        body: bodyByLocale[locale] ?? bodyByLocale.en,
      };
    }

    case "check_company_status": {
      const target = row.target_id || "the company";
      const titleByLocale: Record<string, string> = {
        ru: `Статус компании ${target} обновлён`,
        et: `Ettevõtte ${target} staatus uuendatud`,
        en: `Company status update — ${target}`,
      };
      const bodyByLocale: Record<string, string> = {
        ru:
          `Я обещал перепроверить ${target} (${summary}). ` +
            "Открой Advocat — я готов запустить новую проверку.",
        et:
          `Lubasin ${target} uuesti kontrollida (${summary}). ` +
            "Ava Advocat — alustan kontrolli kohe.",
        en:
          `I promised to re-check ${target} (${summary}). ` +
            "Open Advocat and I'll run the check.",
      };
      return {
        title: titleByLocale[locale] ?? titleByLocale.en,
        body: bodyByLocale[locale] ?? bodyByLocale.en,
      };
    }
  }
}

/**
 * Main loop: fetch due intentions, render notifications, write them, mark
 * each row complete. Pure-ish — all IO is funnelled through MinimalSupabase
 * so tests can swap in a fake.
 */
export async function processDueIntentions(
  supabase: MinimalSupabase,
  now: Date,
  limit = 50,
): Promise<ProcessResult> {
  const due = await supabase.fetchDueIntentions(now, limit);
  let processed = 0;
  let errors = 0;

  for (const row of due) {
    try {
      const email = await supabase.fetchUserEmail(row.user_id);
      if (!email) {
        // No deliverable target — still mark complete so we don't loop forever.
        await supabase.markIntentionComplete(row.id, now);
        continue;
      }
      const { title, body } = renderNotification(row);
      await supabase.insertNotification({
        user_id: row.user_id,
        type: `agent_intention:${row.intent_type}`,
        title,
        body,
      });
      await supabase.markIntentionComplete(row.id, now);
      processed++;
    } catch (_e) {
      // Don't echo error details — they may carry PII (Supabase often
      // includes the failing row in the message).
      errors++;
    }
  }

  return { processed, errors };
}
