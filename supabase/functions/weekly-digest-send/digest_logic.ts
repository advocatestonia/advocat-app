// weekly-digest-send/digest_logic.ts
// -----------------------------------------------------------------------------
// Pure logic helpers extracted from index.ts so they can be Deno-tested
// without spinning up Supabase.
// -----------------------------------------------------------------------------

import type { DigestCaseRow, DigestInsight, Lang } from "../_shared/retention_templates.ts";

/** Days between two dates, rounded down. Negative if `b` is in the past. */
export function daysBetween(a: Date, b: Date): number {
  return Math.floor((b.getTime() - a.getTime()) / (24 * 60 * 60 * 1000));
}

/** Pick the nearest non-completed deadline (negative days = missed, kept). */
export function nearestDeadline(
  deadlines: Array<{
    title: string;
    deadline_at: string;
    status: string;
  }>,
  now: Date,
): { title: string; deadlineAt: string; days: number } | null {
  const candidates = deadlines
    .filter((d) => d.status === "active" || d.status === "missed")
    .map((d) => ({
      title: d.title,
      deadlineAt: d.deadline_at,
      days: daysBetween(now, new Date(d.deadline_at)),
    }))
    .sort((x, y) => x.days - y.days);
  return candidates[0] ?? null;
}

/** Pick deadlines that fall inside the next 14 days (excludes overdue). */
export function deadlinesIn14Days(
  deadlines: Array<{
    title: string;
    deadline_at: string;
    status: string;
    case_title?: string | null;
  }>,
  now: Date,
): Array<{
  title: string;
  deadlineAt: string;
  daysAway: number;
  caseTitle: string;
}> {
  return deadlines
    .filter((d) => d.status === "active")
    .map((d) => ({
      title: d.title,
      deadlineAt: d.deadline_at,
      daysAway: daysBetween(now, new Date(d.deadline_at)),
      caseTitle: d.case_title ?? "",
    }))
    .filter((d) => d.daysAway >= 0 && d.daysAway <= 14)
    .sort((a, b) => a.daysAway - b.daysAway);
}

/**
 * Suggested actions heuristic. Returns 0-3 short imperatives in the user's
 * preferred language. We keep this rule-based (no LLM call) to keep the
 * Monday cron cheap and deterministic — Claude is reserved for genuine
 * content generation, not boilerplate nudges.
 */
export function suggestedActions(args: {
  upcomingDeadlines: Array<{ daysAway: number }>;
  newInsights: number;
  activeCases: number;
  lang: Lang;
}): string[] {
  const out: string[] = [];
  const urgent = args.upcomingDeadlines.filter((d) => d.daysAway < 7).length;
  const SUGG: Record<Lang, Record<string, string>> = {
    en: {
      urgent: "Review the {n} deadline{s} due within a week.",
      insights: "Read the new AI analysis on your case{s}.",
      single: "Open your case to see what's changed.",
      empty: "Quiet week — a good time to upload any new documents.",
    },
    et: {
      urgent: "Vaata üle {n} tähtaeg{s}, mis on nädala sees.",
      insights: "Loe uut AI-analüüsi oma juhtumi kohta.",
      single: "Ava juhtum, et näha, mis on muutunud.",
      empty: "Rahulik nädal — hea aeg uusi dokumente üles laadida.",
    },
    ru: {
      urgent: "Проверьте {n} срок{s} в ближайшую неделю.",
      insights: "Прочтите новый AI-анализ по делу.",
      single: "Откройте дело — посмотрите, что изменилось.",
      empty: "Тихая неделя — хороший момент загрузить новые документы.",
    },
    fi: {
      urgent: "Tarkista {n} määräaika{s} viikon sisällä.",
      insights: "Lue uusi AI-analyysi asiastasi.",
      single: "Avaa asia ja katso mikä on muuttunut.",
      empty: "Hiljainen viikko — hyvä hetki ladata uusia dokumentteja.",
    },
  };
  const s = SUGG[args.lang] ?? SUGG.en;
  if (urgent > 0) {
    out.push(s.urgent
      .replaceAll("{n}", String(urgent))
      .replaceAll("{s}", urgent === 1 ? "" : args.lang === "en" ? "s" : ""));
  }
  if (args.newInsights > 0) {
    out.push(s.insights);
  }
  if (out.length === 0) {
    out.push(args.activeCases === 1 ? s.single : s.empty);
  }
  return out.slice(0, 3);
}

/** Choose UI language. Falls back to 'en' for unsupported codes. */
export function pickLang(code: string | null | undefined): Lang {
  const c = (code ?? "").toLowerCase().slice(0, 2);
  if (c === "et" || c === "ee") return "et";
  if (c === "ru") return "ru";
  if (c === "fi") return "fi";
  return "en";
}

/** Make sure subject-stripping/cropping prevents weirdness in mail clients. */
export function safeSubject(s: string): string {
  return s.replace(/[\r\n\t]/g, " ").slice(0, 250);
}

/** Format an insight blurb from a raw advice_digest entry. */
export function summariseInsight(raw: unknown): string {
  if (typeof raw !== "string") {
    try { raw = JSON.stringify(raw); } catch { /* ignore */ }
  }
  const s = String(raw).trim();
  if (s.length <= 200) return s;
  return s.slice(0, 197) + "...";
}

export interface BuildDigestInput {
  fullName: string;
  email: string;
  preferredLang: string;
  activeCases: Array<{
    id: string;
    title: string;
    status: string;
    advice_digest: Array<{ created_at: string; summary: string }>;
  }>;
  allDeadlines: Array<{
    title: string;
    deadline_at: string;
    status: string;
    case_id: string;
    case_title: string;
  }>;
  lastDigestSentAt: string | null;
  appBaseUrl: string;
  unsubscribeToken: string;
}

/**
 * Pure transformation: raw DB rows → fully populated DigestData (minus the
 * actual render). Index.ts wraps this with the DB fetch + send-mail logic.
 */
export function buildDigestData(input: BuildDigestInput, now: Date) {
  const lang = pickLang(input.preferredLang);

  const cases: DigestCaseRow[] = input.activeCases.map((c) => {
    const caseDeadlines = input.allDeadlines.filter((d) => d.case_id === c.id);
    const nearest = nearestDeadline(caseDeadlines, now);
    return {
      caseId: c.id,
      title: c.title,
      status: c.status,
      nextDeadlineTitle: nearest?.title ?? null,
      nextDeadlineAt: nearest?.deadlineAt ?? null,
      nextDeadlineDays: nearest?.days ?? null,
    };
  });

  const upcoming = deadlinesIn14Days(
    input.allDeadlines.map((d) => ({
      title: d.title,
      deadline_at: d.deadline_at,
      status: d.status,
      case_title: d.case_title,
    })),
    now,
  ).map((d) => ({
    caseTitle: d.caseTitle,
    title: d.title,
    daysAway: d.daysAway,
    deadlineAt: d.deadlineAt,
  }));

  const lastDigest = input.lastDigestSentAt
    ? new Date(input.lastDigestSentAt)
    : new Date(0);
  const newInsights: DigestInsight[] = [];
  for (const c of input.activeCases) {
    for (const a of c.advice_digest ?? []) {
      if (!a?.created_at) continue;
      if (new Date(a.created_at) > lastDigest) {
        newInsights.push({
          caseId: c.id,
          caseTitle: c.title,
          summary: summariseInsight(a.summary),
          createdAt: a.created_at,
        });
      }
    }
  }
  newInsights.sort((a, b) =>
    (b.createdAt ?? "").localeCompare(a.createdAt ?? "")
  );
  const cappedInsights = newInsights.slice(0, 5);

  const actions = suggestedActions({
    upcomingDeadlines: upcoming,
    newInsights: cappedInsights.length,
    activeCases: cases.length,
    lang,
  });

  return {
    fullName: input.fullName,
    email: input.email,
    lang,
    cases,
    upcomingDeadlines: upcoming,
    newInsights: cappedInsights,
    suggestedActions: actions,
    appUrl: input.appBaseUrl,
    unsubscribeUrl:
      `${input.appBaseUrl}/u/${input.unsubscribeToken}?k=digest`,
  };
}
