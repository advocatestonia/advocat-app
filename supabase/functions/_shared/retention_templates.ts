// _shared/retention_templates.ts
// -----------------------------------------------------------------------------
// HTML + plain-text email templates for the three retention loops:
//   * weekly_digest        — Monday 08:00 Europe/Tallinn
//   * winback_d3 / d7 / d14 — re-engagement after inactivity
//
// All templates are pure functions: (data, lang) -> { html, text, subject }.
// No I/O, no Supabase calls — those live in the edge fn handlers.
//
// Localisation: EN / ET / RU / FI. Falls back to EN.
//
// Compliance:
//   * Every HTML body MUST include the per-user unsubscribe link
//     (built from notification_preferences.unsubscribe_token).
//   * Body footers mention Advocat OÜ, support@advocat.ee, and the user's
//     account email (so the recipient knows why they got the message).
//   * Tracking pixel uses ${trackingPixelUrl}; downstream is responsible
//     for wiring a /track/open endpoint (out of scope here — pixel renders
//     a 1×1 transparent gif when the URL resolves).
// -----------------------------------------------------------------------------

export type Lang = "en" | "et" | "ru" | "fi";

export interface DigestCaseRow {
  caseId: string;
  title: string;
  status: string;
  nextDeadlineTitle: string | null;
  nextDeadlineAt: string | null;     // ISO
  nextDeadlineDays: number | null;   // can be negative if missed
}

export interface DigestInsight {
  caseId: string;
  caseTitle: string;
  summary: string;                    // <=200 chars
  createdAt: string;
}

export interface DigestData {
  fullName: string;
  email: string;                      // recipient (footer)
  lang: Lang;
  cases: DigestCaseRow[];
  upcomingDeadlines: Array<{
    caseTitle: string;
    title: string;
    daysAway: number;
    deadlineAt: string;
  }>;
  newInsights: DigestInsight[];
  suggestedActions: string[];         // 1-3 short imperatives
  appUrl: string;                     // CTA target (deep link)
  unsubscribeUrl: string;             // one-click unsubscribe
  trackingPixelUrl?: string;          // open-tracking pixel
}

export interface WinbackData {
  fullName: string;
  email: string;
  lang: Lang;
  daysInactive: number;
  appUrl: string;
  unsubscribeUrl: string;
  trackingPixelUrl?: string;
  promoCode?: string;                 // only present for d14
}

export interface RenderedEmail {
  subject: string;
  html: string;
  text: string;
}

// ── L10n strings ──────────────────────────────────────────────────────────

const STRINGS: Record<Lang, Record<string, string>> = {
  en: {
    digestSubject:
      "Your week with Advocat: {deadlines} deadlines, {insights} new insights",
    digestGreeting: "Good morning,",
    digestIntro: "Here's where your legal matters stand this week.",
    sectionCases: "Active cases",
    sectionDeadlines: "Deadlines in the next 14 days",
    sectionInsights: "New AI insights",
    sectionActions: "Suggested next steps",
    cta: "Open in Advocat →",
    noDeadlines: "No deadlines in the next 14 days. Nice and quiet.",
    noInsights: "No new AI analysis since your last digest.",
    daysAway: "in {n} days",
    today: "today",
    overdue: "overdue {n}d",
    footerSentTo: "Sent to {email}",
    footerWhy: "You're getting this because you have at least one active case in Advocat.",
    unsub: "Manage notification preferences",
    winbackD3Subject: "Did the contract review work for you?",
    winbackD3Body:
      "Hi {name}, it's been a few days since you tried Advocat. " +
      "How did it go? If anything was unclear or didn't help, " +
      "reply to this email — we read every response.",
    winbackD3Cta: "Continue where you left off",
    winbackD7Subject: "Try a sample case (no commitment)",
    winbackD7Body:
      "Hi {name}, we noticed you haven't been back in a week. " +
      "Most users find Advocat clicks once they try a real case. " +
      "Tap below for a 90-second sample walkthrough.",
    winbackD7Cta: "Open sample case",
    winbackD14Subject: "We miss you — here's a free month on us",
    winbackD14Body:
      "Hi {name}, you've been away for two weeks. " +
      "If life got busy, that's fine — but if Advocat didn't earn its place, " +
      "we'd like one more chance. Code {code} gives you Premium for 30 days, " +
      "free.",
    winbackD14Cta: "Redeem free month",
  },
  et: {
    digestSubject:
      "Sinu nädal Advocatiga: {deadlines} tähtaega, {insights} uut analüüsi",
    digestGreeting: "Tere hommikust,",
    digestIntro: "Vaata, mis su juriidiliste asjadega sel nädalal toimub.",
    sectionCases: "Aktiivsed juhtumid",
    sectionDeadlines: "Tähtajad järgmise 14 päeva jooksul",
    sectionInsights: "Uued AI-analüüsid",
    sectionActions: "Soovitatud järgmised sammud",
    cta: "Ava Advocatis →",
    noDeadlines: "Järgneva 14 päeva jooksul tähtaegu pole. Vaikne nädal.",
    noInsights: "Pärast eelmist kokkuvõtet uusi AI-analüüse pole.",
    daysAway: "{n} päeva pärast",
    today: "täna",
    overdue: "üle aja {n}p",
    footerSentTo: "Saadetud aadressile {email}",
    footerWhy: "Said selle, sest sul on Advocatis vähemalt üks aktiivne juhtum.",
    unsub: "Halda teavitusi",
    winbackD3Subject: "Kas lepingu ülevaatus toimis?",
    winbackD3Body:
      "Tere {name}, sa proovisid Advocati paar päeva tagasi. " +
      "Kuidas läks? Kui midagi jäi segaseks, vasta sellele kirjale — " +
      "loeme iga vastust.",
    winbackD3Cta: "Jätka sealt, kus pooleli jäi",
    winbackD7Subject: "Proovi näidisjuhtumit (kohustusteta)",
    winbackD7Body:
      "Tere {name}, märkasime, et pole nädalat tagasi tulnud. " +
      "Enamik kasutajaid mõistab Advocati alles siis, kui proovib " +
      "päris juhtumit. Vajuta allpool 90-sekundilise näidise jaoks.",
    winbackD7Cta: "Ava näidisjuhtum",
    winbackD14Subject: "Igatseme sind — tasuta kuu sulle",
    winbackD14Body:
      "Tere {name}, oled olnud eemal kaks nädalat. " +
      "Kui elu sai kiireks, on see okei — aga kui Advocat ei teeninud oma kohta välja, " +
      "tahaksime veel ühe võimaluse. Kood {code} annab sulle 30 päeva Premiumit tasuta.",
    winbackD14Cta: "Lunasta tasuta kuu",
  },
  ru: {
    digestSubject:
      "Ваша неделя с Advocat: {deadlines} сроков, {insights} новых анализов",
    digestGreeting: "Доброе утро,",
    digestIntro: "Вот что происходит с вашими юридическими делами на этой неделе.",
    sectionCases: "Активные дела",
    sectionDeadlines: "Сроки в ближайшие 14 дней",
    sectionInsights: "Новые AI-инсайты",
    sectionActions: "Рекомендуемые шаги",
    cta: "Открыть в Advocat →",
    noDeadlines: "В ближайшие 14 дней сроков нет. Тихая неделя.",
    noInsights: "Со времени прошлого дайджеста новых AI-анализов нет.",
    daysAway: "через {n} дней",
    today: "сегодня",
    overdue: "просрочено {n}д",
    footerSentTo: "Отправлено на {email}",
    footerWhy: "Вы получили это письмо, потому что у вас есть активное дело в Advocat.",
    unsub: "Настройки уведомлений",
    winbackD3Subject: "Помог ли разбор контракта?",
    winbackD3Body:
      "Привет, {name}. Несколько дней назад вы пробовали Advocat. " +
      "Как впечатления? Если что-то осталось непонятным, ответьте на это письмо — " +
      "мы читаем каждый ответ.",
    winbackD3Cta: "Продолжить с того места",
    winbackD7Subject: "Попробуйте пример дела (без обязательств)",
    winbackD7Body:
      "Привет, {name}. Заметили, что вас не было неделю. " +
      "Большинство понимает суть Advocat после первого реального дела. " +
      "Нажмите ниже — это 90-секундный пример.",
    winbackD7Cta: "Открыть пример дела",
    winbackD14Subject: "Скучаем — дарим бесплатный месяц",
    winbackD14Body:
      "Привет, {name}. Вас не было две недели. " +
      "Если просто стало некогда — мы понимаем. Но если Advocat не оправдал ожиданий — " +
      "дайте ещё один шанс. Код {code} = Premium на 30 дней бесплатно.",
    winbackD14Cta: "Активировать бесплатный месяц",
  },
  fi: {
    digestSubject:
      "Viikkosi Advocatissa: {deadlines} määräaikaa, {insights} uutta analyysiä",
    digestGreeting: "Hyvää huomenta,",
    digestIntro: "Tässä viikkokatsaus juridisiin asioihisi.",
    sectionCases: "Aktiiviset asiat",
    sectionDeadlines: "Määräajat seuraavan 14 päivän aikana",
    sectionInsights: "Uudet AI-analyysit",
    sectionActions: "Suositellut seuraavat askeleet",
    cta: "Avaa Advocatissa →",
    noDeadlines: "Ei määräaikoja seuraavan 14 päivän aikana.",
    noInsights: "Edellisen koosteen jälkeen ei uusia analyyseja.",
    daysAway: "{n} päivän kuluttua",
    today: "tänään",
    overdue: "myöhässä {n}pv",
    footerSentTo: "Lähetetty osoitteeseen {email}",
    footerWhy: "Saat tämän, koska sinulla on Advocatissa aktiivinen asia.",
    unsub: "Hallinnoi ilmoituksia",
    winbackD3Subject: "Toimiko sopimustarkistus?",
    winbackD3Body:
      "Hei {name}, kokeilit Advocatia muutama päivä sitten. " +
      "Miten meni? Jos jokin jäi epäselväksi, vastaa tähän viestiin.",
    winbackD3Cta: "Jatka siitä mihin jäit",
    winbackD7Subject: "Kokeile esimerkkitapausta (ei sitoumuksia)",
    winbackD7Body:
      "Hei {name}, et ole käynyt viikkoon. " +
      "Useimmat tajuavat Advocatin idean vasta kokeillessaan oikeaa asiaa. " +
      "Klikkaa 90 sekunnin esimerkkiin.",
    winbackD7Cta: "Avaa esimerkki",
    winbackD14Subject: "Kaipaamme sinua — ilmainen kuukausi",
    winbackD14Body:
      "Hei {name}, olet ollut pois kaksi viikkoa. " +
      "Jos arki kiirehti, ei hätää. Mutta jos Advocat ei ansainnut paikkaansa, " +
      "haluamme yhden mahdollisuuden lisää. Koodi {code} = Premium 30 päiväksi.",
    winbackD14Cta: "Lunasta ilmainen kuukausi",
  },
};

function t(lang: Lang, key: string, vars: Record<string, string | number> = {}): string {
  const dict = STRINGS[lang] ?? STRINGS.en;
  let s = dict[key] ?? STRINGS.en[key] ?? key;
  for (const [k, v] of Object.entries(vars)) {
    s = s.replaceAll(`{${k}}`, String(v));
  }
  return s;
}

// ── Helpers ────────────────────────────────────────────────────────────────

function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function formatDays(days: number, lang: Lang): string {
  if (days === 0) return t(lang, "today");
  if (days < 0) return t(lang, "overdue", { n: -days });
  return t(lang, "daysAway", { n: days });
}

function deadlineColor(days: number): string {
  if (days < 0) return "#9c1c1c";   // overdue — dark red
  if (days < 7) return "#c91c1c";   // red
  if (days < 14) return "#c9881c";  // amber
  return "#1c6cc9";                  // blue
}

// ── Weekly digest ──────────────────────────────────────────────────────────

export function renderDigest(data: DigestData): RenderedEmail {
  const lang = data.lang;
  const deadlineCount = data.upcomingDeadlines.length;
  const insightCount = data.newInsights.length;

  const subject = t(lang, "digestSubject", {
    deadlines: deadlineCount,
    insights: insightCount,
  });

  // Cases
  const casesHtml = data.cases.map((c) => {
    const dl = c.nextDeadlineAt
      ? `<div style="color:${deadlineColor(c.nextDeadlineDays ?? 99)};font-size:13px;margin-top:4px;">` +
        `${esc(c.nextDeadlineTitle ?? "")} · ${esc(formatDays(c.nextDeadlineDays ?? 99, lang))}</div>`
      : "";
    return `
      <div style="padding:12px 14px;border:1px solid #e4e4e7;border-radius:8px;margin-bottom:8px;background:#fafafa;">
        <div style="font-weight:600;font-size:15px;color:#0f172a;">${esc(c.title)}</div>
        <div style="color:#64748b;font-size:13px;margin-top:2px;">${esc(c.status)}</div>
        ${dl}
      </div>`;
  }).join("");

  // Deadlines
  const deadlinesHtml = deadlineCount === 0
    ? `<p style="color:#64748b;font-size:14px;">${esc(t(lang, "noDeadlines"))}</p>`
    : data.upcomingDeadlines.map((d) => {
        const color = deadlineColor(d.daysAway);
        return `
          <div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #f1f5f9;">
            <div>
              <div style="font-weight:600;color:#0f172a;font-size:14px;">${esc(d.title)}</div>
              <div style="color:#64748b;font-size:12px;">${esc(d.caseTitle)}</div>
            </div>
            <div style="color:${color};font-weight:600;font-size:13px;align-self:center;">
              ${esc(formatDays(d.daysAway, lang))}
            </div>
          </div>`;
      }).join("");

  // Insights
  const insightsHtml = insightCount === 0
    ? `<p style="color:#64748b;font-size:14px;">${esc(t(lang, "noInsights"))}</p>`
    : data.newInsights.map((i) => `
        <div style="padding:10px 0;border-bottom:1px solid #f1f5f9;">
          <div style="font-weight:600;color:#0f172a;font-size:14px;">${esc(i.caseTitle)}</div>
          <div style="color:#475569;font-size:13px;margin-top:2px;">${esc(i.summary)}</div>
        </div>`).join("");

  // Actions
  const actionsHtml = data.suggestedActions.length === 0
    ? ""
    : `<ul style="padding-left:20px;margin:8px 0;color:#0f172a;font-size:14px;">` +
      data.suggestedActions.map((a) => `<li style="margin-bottom:4px;">${esc(a)}</li>`).join("") +
      `</ul>`;

  const pixel = data.trackingPixelUrl
    ? `<img src="${esc(data.trackingPixelUrl)}" width="1" height="1" style="display:block;" alt="">`
    : "";

  const html = `<!doctype html>
<html lang="${lang}">
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#f8fafc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#0f172a;">
  <div style="max-width:560px;margin:0 auto;padding:24px 16px;">
    <div style="font-size:20px;font-weight:700;color:#0f172a;letter-spacing:-0.01em;">
      Advocat
    </div>
    <h1 style="font-size:24px;font-weight:700;margin:24px 0 8px;color:#0f172a;">
      ${esc(t(lang, "digestGreeting"))}
    </h1>
    <p style="color:#475569;font-size:15px;margin:0 0 24px;">
      ${esc(t(lang, "digestIntro"))}
    </p>

    <h2 style="font-size:14px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.05em;margin:24px 0 12px;">
      ${esc(t(lang, "sectionCases"))}
    </h2>
    ${casesHtml}

    <h2 style="font-size:14px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.05em;margin:24px 0 12px;">
      ${esc(t(lang, "sectionDeadlines"))}
    </h2>
    ${deadlinesHtml}

    <h2 style="font-size:14px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.05em;margin:24px 0 12px;">
      ${esc(t(lang, "sectionInsights"))}
    </h2>
    ${insightsHtml}

    ${data.suggestedActions.length > 0 ? `
      <h2 style="font-size:14px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.05em;margin:24px 0 12px;">
        ${esc(t(lang, "sectionActions"))}
      </h2>
      ${actionsHtml}
    ` : ""}

    <div style="margin:32px 0;text-align:center;">
      <a href="${esc(data.appUrl)}" style="display:inline-block;background:#0f172a;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;font-size:15px;">
        ${esc(t(lang, "cta"))}
      </a>
    </div>

    <hr style="border:none;border-top:1px solid #e4e4e7;margin:32px 0 16px;">
    <div style="color:#94a3b8;font-size:12px;line-height:1.5;">
      <div>${esc(t(lang, "footerSentTo", { email: data.email }))}</div>
      <div>${esc(t(lang, "footerWhy"))}</div>
      <div style="margin-top:8px;">
        <a href="${esc(data.unsubscribeUrl)}" style="color:#64748b;">${esc(t(lang, "unsub"))}</a>
        &nbsp;·&nbsp;Advocat OÜ · support@advocat.ee
      </div>
    </div>
    ${pixel}
  </div>
</body>
</html>`;

  const text = renderDigestText(data, lang);
  return { subject, html, text };
}

function renderDigestText(data: DigestData, lang: Lang): string {
  const lines: string[] = [];
  lines.push(t(lang, "digestGreeting"));
  lines.push("");
  lines.push(t(lang, "digestIntro"));
  lines.push("");
  lines.push(`== ${t(lang, "sectionCases")} ==`);
  for (const c of data.cases) {
    lines.push(`• ${c.title} (${c.status})`);
    if (c.nextDeadlineAt && c.nextDeadlineDays !== null) {
      lines.push(`  ${c.nextDeadlineTitle} — ${formatDays(c.nextDeadlineDays, lang)}`);
    }
  }
  lines.push("");
  lines.push(`== ${t(lang, "sectionDeadlines")} ==`);
  if (data.upcomingDeadlines.length === 0) {
    lines.push(t(lang, "noDeadlines"));
  } else {
    for (const d of data.upcomingDeadlines) {
      lines.push(`• ${d.title} (${d.caseTitle}) — ${formatDays(d.daysAway, lang)}`);
    }
  }
  lines.push("");
  lines.push(`== ${t(lang, "sectionInsights")} ==`);
  if (data.newInsights.length === 0) {
    lines.push(t(lang, "noInsights"));
  } else {
    for (const i of data.newInsights) {
      lines.push(`• ${i.caseTitle}: ${i.summary}`);
    }
  }
  if (data.suggestedActions.length > 0) {
    lines.push("");
    lines.push(`== ${t(lang, "sectionActions")} ==`);
    for (const a of data.suggestedActions) {
      lines.push(`• ${a}`);
    }
  }
  lines.push("");
  lines.push(`${t(lang, "cta")} ${data.appUrl}`);
  lines.push("");
  lines.push("—");
  lines.push(t(lang, "footerSentTo", { email: data.email }));
  lines.push(t(lang, "footerWhy"));
  lines.push(`${t(lang, "unsub")}: ${data.unsubscribeUrl}`);
  lines.push("Advocat OÜ · support@advocat.ee");
  return lines.join("\n");
}

// ── Winback emails ─────────────────────────────────────────────────────────

export function renderWinback(
  data: WinbackData,
  step: "d3" | "d7" | "d14",
): RenderedEmail {
  const lang = data.lang;
  const firstName = data.fullName.split(" ")[0] || "there";

  const subjectKey = step === "d3"
    ? "winbackD3Subject"
    : step === "d7" ? "winbackD7Subject" : "winbackD14Subject";
  const bodyKey = step === "d3"
    ? "winbackD3Body"
    : step === "d7" ? "winbackD7Body" : "winbackD14Body";
  const ctaKey = step === "d3"
    ? "winbackD3Cta"
    : step === "d7" ? "winbackD7Cta" : "winbackD14Cta";

  const subject = t(lang, subjectKey);
  const bodyText = t(lang, bodyKey, {
    name: firstName,
    code: data.promoCode || "ADVOCAT30",
  });
  const ctaText = t(lang, ctaKey);

  const pixel = data.trackingPixelUrl
    ? `<img src="${esc(data.trackingPixelUrl)}" width="1" height="1" style="display:block;" alt="">`
    : "";

  const html = `<!doctype html>
<html lang="${lang}">
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#f8fafc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#0f172a;">
  <div style="max-width:520px;margin:0 auto;padding:32px 16px;">
    <div style="font-size:20px;font-weight:700;color:#0f172a;letter-spacing:-0.01em;">
      Advocat
    </div>
    <div style="margin-top:32px;color:#0f172a;font-size:16px;line-height:1.6;">
      ${esc(bodyText)}
    </div>
    <div style="margin:32px 0;text-align:center;">
      <a href="${esc(data.appUrl)}" style="display:inline-block;background:#0f172a;color:#fff;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:600;font-size:15px;">
        ${esc(ctaText)}
      </a>
    </div>
    <hr style="border:none;border-top:1px solid #e4e4e7;margin:32px 0 16px;">
    <div style="color:#94a3b8;font-size:12px;line-height:1.5;">
      <div>${esc(t(lang, "footerSentTo", { email: data.email }))}</div>
      <div style="margin-top:8px;">
        <a href="${esc(data.unsubscribeUrl)}" style="color:#64748b;">${esc(t(lang, "unsub"))}</a>
        &nbsp;·&nbsp;Advocat OÜ · support@advocat.ee
      </div>
    </div>
    ${pixel}
  </div>
</body>
</html>`;

  const text =
    `${bodyText}\n\n` +
    `${ctaText}: ${data.appUrl}\n\n` +
    `—\n` +
    `${t(lang, "footerSentTo", { email: data.email })}\n` +
    `${t(lang, "unsub")}: ${data.unsubscribeUrl}\n` +
    `Advocat OÜ · support@advocat.ee\n`;

  return { subject, html, text };
}

// ── Building blocks (exposed for tests) ────────────────────────────────────

export const __testing__ = { t, esc, formatDays, deadlineColor };
