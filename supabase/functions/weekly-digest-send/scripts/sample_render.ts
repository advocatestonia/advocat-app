// One-shot sample rendering for owner inspection.
// Run with:
//   deno run --allow-write --allow-read \
//     supabase/functions/weekly-digest-send/scripts/sample_render.ts \
//     /tmp/digest_sample.html
//
// Generates a representative weekly digest using Sulga-like data so the
// owner can eyeball the visual without spinning up a DB.

import { buildDigestData } from "../digest_logic.ts";
import { renderDigest, renderWinback } from "../../_shared/retention_templates.ts";

const NOW = new Date("2026-05-18T08:00:00+03:00");

const digestData = buildDigestData(
  {
    fullName: "Dmitri Sulga",
    email: "dmitri@example.com",
    preferredLang: "ru",
    activeCases: [
      {
        id: "case-1",
        title: "Sulga v. Finland — KHO valituslupa",
        status: "active",
        advice_digest: [
          {
            created_at: "2026-05-17T14:00:00Z",
            summary:
              "Финляндские власти допустили три систематические идентификационные ошибки в деле о депортации (Neuvostoliitto, allekirjoitusvirhe, Dimitri/Dmitri). " +
              "Это создаёт основу для erityisen painava syy в KHO.",
          },
          {
            created_at: "2026-05-15T09:00:00Z",
            summary:
              "Получено письмо от Jokela — она просит копию страницы 4 käännytyspäätös. " +
              "Эта страница отсутствует в материалах. Подготовлен ответ.",
          },
        ],
      },
      {
        id: "case-2",
        title: "Track-B Hallintoasia",
        status: "active",
        advice_digest: [],
      },
    ],
    allDeadlines: [
      {
        title: "KHO valituslupa",
        deadline_at: "2026-06-05T00:00:00+03:00",
        status: "active",
        case_id: "case-1",
        case_title: "Sulga v. Finland — KHO valituslupa",
      },
      {
        title: "Vistjak lausunto request reply",
        deadline_at: "2026-05-23T00:00:00+03:00",
        status: "active",
        case_id: "case-2",
        case_title: "Track-B Hallintoasia",
      },
      {
        title: "ESTO arve",
        deadline_at: "2026-05-15T00:00:00+03:00",
        status: "missed",
        case_id: "case-2",
        case_title: "Track-B Hallintoasia",
      },
    ],
    lastDigestSentAt: "2026-05-11T08:00:00+03:00",
    appBaseUrl: "https://advocat.ee/app",
    unsubscribeToken: "00000000-1111-2222-3333-444444444444",
  },
  NOW,
);

const digest = renderDigest(digestData);

const winbackD3 = renderWinback(
  {
    fullName: "Maria Tamm",
    email: "maria@example.ee",
    lang: "et",
    daysInactive: 3,
    appUrl: "https://advocat.ee/app",
    unsubscribeUrl:
      "https://advocat.ee/app/u/55555555-6666-7777-8888-999999999999?k=winback",
  },
  "d3",
);

const winbackD7 = renderWinback(
  {
    fullName: "Maria Tamm",
    email: "maria@example.ee",
    lang: "et",
    daysInactive: 7,
    appUrl: "https://advocat.ee/app",
    unsubscribeUrl:
      "https://advocat.ee/app/u/55555555-6666-7777-8888-999999999999?k=winback",
  },
  "d7",
);

const winbackD14 = renderWinback(
  {
    fullName: "Maria Tamm",
    email: "maria@example.ee",
    lang: "et",
    daysInactive: 14,
    appUrl: "https://advocat.ee/app",
    unsubscribeUrl:
      "https://advocat.ee/app/u/55555555-6666-7777-8888-999999999999?k=winback",
    promoCode: "ADV-XYZ789",
  },
  "d14",
);

const outPath = Deno.args[0] ?? "/tmp/digest_sample.html";

const combined = `<!doctype html>
<html><head><meta charset="utf-8"><title>Retention email samples</title>
<style>body{background:#222;color:#eee;font-family:sans-serif;}
h1{margin:32px 16px;}
.frame{background:#fff;color:#000;margin:0 16px 32px;border-radius:8px;overflow:hidden;}
.meta{padding:12px 16px;background:#eef2ff;color:#3730a3;font-family:monospace;font-size:13px;}
iframe{width:100%;border:none;display:block;}
</style></head><body>
<h1>Advocat — Retention emails (sample)</h1>

<div class="frame">
  <div class="meta">SUBJECT: ${digest.subject}</div>
  <iframe srcdoc="${digest.html.replace(/"/g, "&quot;")}" height="1400"></iframe>
</div>

<h1>Winback Day 3 (ET)</h1>
<div class="frame">
  <div class="meta">SUBJECT: ${winbackD3.subject}</div>
  <iframe srcdoc="${winbackD3.html.replace(/"/g, "&quot;")}" height="500"></iframe>
</div>

<h1>Winback Day 7 (ET)</h1>
<div class="frame">
  <div class="meta">SUBJECT: ${winbackD7.subject}</div>
  <iframe srcdoc="${winbackD7.html.replace(/"/g, "&quot;")}" height="500"></iframe>
</div>

<h1>Winback Day 14 (ET) — with promo code</h1>
<div class="frame">
  <div class="meta">SUBJECT: ${winbackD14.subject}</div>
  <iframe srcdoc="${winbackD14.html.replace(/"/g, "&quot;")}" height="500"></iframe>
</div>

</body></html>`;

await Deno.writeTextFile(outPath, combined);
console.log(`Wrote sample to ${outPath}`);
console.log("");
console.log("Digest subject:    ", digest.subject);
console.log("Winback d3 subject:", winbackD3.subject);
console.log("Winback d7 subject:", winbackD7.subject);
console.log("Winback d14 subject:", winbackD14.subject);
console.log("");
console.log(`Digest HTML size: ${digest.html.length.toLocaleString()} chars`);
console.log(`Digest text size: ${digest.text.length.toLocaleString()} chars`);
