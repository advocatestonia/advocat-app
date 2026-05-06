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
    deep_link?: string;
  }): Promise<void>;
  markIntentionComplete(id: string, now: Date): Promise<void>;

  /// D7 — fetch unseen CRITICAL/HIGH triage rows across all users so the
  /// cron can push notifications before the user opens Advocat. Rows are
  /// the JOIN of `email_triage_results` with the parent `email_threads` so
  /// the title/body can reference the subject.
  fetchUnseenCriticalTriage?(limit: number): Promise<TriagePushRow[]>;

  /// D7 — stamp seen_by_user_at on the triage row so the cron does not
  /// re-push on the next tick.
  markTriageSeen?(triageId: string, now: Date): Promise<void>;
}

export interface TriagePushRow {
  id: string;            // email_triage_results.id
  thread_id: string;     // email_threads.id
  user_id: string;
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  draft_language: string | null;
  user_brief: string | null;
  subject: string | null;
  sender_email: string | null;
}

export interface ProcessResult {
  processed: number;
  errors: number;
  /// D7 — number of triage rows pushed in this tick.
  triagePushed?: number;
  triageErrors?: number;
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

  // ── D7 — push unseen CRITICAL/HIGH email-triage rows ───────────────────
  // The triage edge fn (D4) writes rows into email_triage_results without
  // sending push notifications itself. The hourly cron fans out a single
  // push per unseen high-severity row and stamps seen_by_user_at to make
  // the operation idempotent. MEDIUM/LOW stay in-app only (per spec).
  let triagePushed = 0;
  let triageErrors = 0;

  if (
    typeof supabase.fetchUnseenCriticalTriage === "function" &&
    typeof supabase.markTriageSeen === "function"
  ) {
    try {
      const rows = await supabase.fetchUnseenCriticalTriage(limit);
      for (const t of rows) {
        try {
          const { title, body } = renderTriageNotification(t);
          await supabase.insertNotification({
            user_id: t.user_id,
            type: `email_triage:${t.severity.toLowerCase()}`,
            title,
            body,
            deep_link: `advocat://inbox/thread/${t.thread_id}`,
          });
          await supabase.markTriageSeen(t.id, now);
          triagePushed++;
        } catch (_e) {
          triageErrors++;
        }
      }
    } catch (_e) {
      triageErrors++;
    }
  }

  return {
    processed,
    errors,
    triagePushed,
    triageErrors,
  };
}

/**
 * D7 — render the push for a single unseen CRITICAL/HIGH triage row.
 *
 * Localised by `draft_language` (the language the model picked for the
 * reply, which is the user's working language for that thread). Pure — no
 * IO. The body is capped at 140 chars per spec §D7.
 */
export function renderTriageNotification(
  t: TriagePushRow,
): { title: string; body: string } {
  const lang = (t.draft_language || "en").toLowerCase();
  const titleByLocale: Record<string, Record<string, string>> = {
    CRITICAL: {
      ru: "Срочно: ответ требуется сегодня",
      et: "Kiire: vastust vaja täna",
      fi: "Kiireellinen: vastausta tänään",
      en: "Urgent: response needed today",
    },
    HIGH: {
      ru: "Важно: новое письмо требует внимания",
      et: "Tähtis: uus kiri vajab tähelepanu",
      fi: "Tärkeää: uusi sähköposti vaatii huomiota",
      en: "Important: new email needs attention",
    },
  };

  const titles = titleByLocale[t.severity] ?? titleByLocale.HIGH;
  const subject = (t.subject || "").trim();
  const sender = (t.sender_email || "").trim();
  const baseTitle = titles[lang] ?? titles.en;
  const title = subject ? `${baseTitle} — ${subject}` : baseTitle;

  // Spec §D7: body = user_brief.slice(0, 140). Fall back to "<sender>: ..."
  // when the brief is missing so the user always sees something useful.
  const brief = (t.user_brief || "").trim();
  const fallbackBody = sender ? `${sender}: ${subject || ""}`.trim() : subject;
  const raw = brief.length > 0 ? brief : fallbackBody;
  const body = raw.slice(0, 140);

  return { title, body };
}
